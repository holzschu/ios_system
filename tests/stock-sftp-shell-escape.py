#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["typer", "rich"]
# ///
"""Run Stock sftp local shell escapes in a worker-enabled a-Shell host on an iOS Simulator."""

import getpass
import re
import shlex
import shutil
import socket
import subprocess
import tempfile
import time
from contextlib import ExitStack, contextmanager
from pathlib import Path
from uuid import UUID

import typer
from rich.console import Console

HOST = "127.0.0.1"
LISTED = "STOCK_SFTP_LISTED_FILE"
REDIRECTED = "STOCK_SFTP_REDIRECTED_INPUT"
REMOTE = "Remote working directory:"
NO_SHELL = "Interactive local shell is not available"
# sftp and its ssh transport each hold a worker, so this limit leaves none for "!".
BUSY_LIMIT = 2


def simctl(*args, check=True, **kwargs):
    return subprocess.run(["xcrun", "simctl", *args], check=check, **kwargs)


def free_port():
    with socket.socket() as s:
        s.bind((HOST, 0))
        return s.getsockname()[1]


@contextmanager
def sshd(root, port, client_pub):
    key = root / "host"
    subprocess.run(
        ["/usr/bin/ssh-keygen", "-qt", "ed25519", "-N", "", "-f", key], check=True
    )
    config = root / "sshd.conf"
    config.write_text(f"""\
ListenAddress {HOST}
Port {port}
HostKey "{key}"
AuthorizedKeysFile "{client_pub}"
AllowUsers {getpass.getuser()}
AuthenticationMethods publickey
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM no
PerSourcePenalties no
StrictModes no
Subsystem sftp internal-sftp
""")
    with (
        (root / "sshd.log").open("wb") as log,
        subprocess.Popen(
            ["/usr/sbin/sshd", "-D", "-e", "-f", config], stderr=log
        ) as server,
    ):
        try:
            deadline = time.monotonic() + 5
            while True:
                if server.poll() is not None:
                    raise RuntimeError(
                        f"sshd exited {server.returncode}: "
                        + (root / "sshd.log").read_text().strip()
                    )
                try:
                    with socket.create_connection((HOST, port), timeout=0.1):
                        break
                except OSError:
                    if time.monotonic() >= deadline:
                        raise RuntimeError("Timed out waiting for sshd")
                    time.sleep(0.05)
            yield key.with_suffix(".pub")
        finally:
            server.terminate()
            try:
                server.wait(timeout=3)
            except subprocess.TimeoutExpired:
                server.kill()


@contextmanager
def preserved(path):
    before = path.read_bytes() if path.exists() else None
    try:
        yield
    finally:
        if before is None:
            path.unlink(missing_ok=True)
        else:
            path.write_bytes(before)


@contextmanager
def worker_limit(simulator, bundle_id, value):
    defaults = ["spawn", str(simulator), "defaults"]
    read = subprocess.run(
        ["xcrun", "simctl", *defaults, "read", bundle_id, "worker_limit"],
        check=False,
        capture_output=True,
        text=True,
    )
    before = read.stdout.strip() if read.returncode == 0 else None
    simctl(*defaults, "write", bundle_id, "worker_limit", "-int", str(value))
    try:
        yield
    finally:
        if before is None:
            simctl(*defaults, "delete", bundle_id, "worker_limit", check=False)
        else:
            simctl(*defaults, "write", bundle_id, "worker_limit", "-int", before)


def run_profile(simulator, bundle_id, documents, lines, done, timeout):
    """Run LINES as the app's .profile and wait until it writes DONE."""
    stop = ["xcrun", "simctl", "terminate", str(simulator), bundle_id]
    with preserved(documents / ".profile"):
        (documents / ".profile").write_text(
            "".join(f"{line}\n" for line in lines)
            + f"echo done > {shlex.quote(str(done))}\n"
        )
        subprocess.run(stop, check=False, capture_output=True)
        try:
            simctl("launch", str(simulator), bundle_id, capture_output=True)
            deadline = time.monotonic() + timeout
            while not done.exists():
                if time.monotonic() >= deadline:
                    return False
                time.sleep(0.5)
            return True
        finally:
            subprocess.run(stop, check=False, capture_output=True)


def main(simulator: UUID, bundle_id: str, timeout: float = 60.0):
    """Run against a booted Simulator with the worker-enabled app BUNDLE_ID installed."""
    console = Console(stderr=True)
    try:
        documents = (
            Path(
                simctl(
                    "get_app_container",
                    str(simulator),
                    bundle_id,
                    "data",
                    capture_output=True,
                    text=True,
                ).stdout.strip()
            )
            / "Documents"
        )
        with (
            tempfile.TemporaryDirectory(prefix="stock-sftp-shell-escape-") as work,
            ExitStack() as stack,
        ):
            root = Path(work)
            client = root / "client"
            subprocess.run(
                ["/usr/bin/ssh-keygen", "-qt", "ed25519", "-N", "", "-f", client],
                check=True,
            )
            port = free_port()
            host_key = stack.enter_context(sshd(root, port, client.with_suffix(".pub")))
            case_dir = documents / f"stock-sftp-shell-escape-{time.time_ns()}"
            case_dir.mkdir()
            stack.callback(shutil.rmtree, case_dir, ignore_errors=True)
            (case_dir / "client").write_bytes(client.read_bytes())
            (case_dir / "client").chmod(0o600)
            listed = case_dir / "listed"
            listed.mkdir()
            (listed / LISTED).touch()
            local_input = case_dir / "input"
            local_input.write_text(f"{REDIRECTED}\n")
            known = case_dir / "known_hosts"
            known.write_text(
                f"[{HOST}]:{port} " + " ".join(host_key.read_text().split()[:2]) + "\n"
            )
            config = case_dir / "config"
            config.write_text(
                f"Host target\n  HostName {HOST}\n  Port {port}\n  User {getpass.getuser()}\n"
                f"  IdentityFile {case_dir / 'client'}\n  IdentitiesOnly yes\n"
                f"  UserKnownHostsFile {known}\n  StrictHostKeyChecking yes\n  BatchMode yes\n"
            )

            def sftp(name, commands):
                batch = case_dir / f"{name}.batch"
                batch.write_text("".join(f"{c}\n" for c in commands))
                out = shlex.quote(str(case_dir / name))
                return (
                    shlex.join(["sftp", "-F", str(config), "-b", str(batch), "target"])
                    + f" > {out}.out 2> {out}.err"
                )

            def read(name):
                return (
                    (case_dir / f"{name}.out").read_text(errors="replace"),
                    (case_dir / f"{name}.err").read_text(errors="replace"),
                )

            failures = []
            ran = run_profile(
                simulator,
                bundle_id,
                documents,
                [
                    sftp(
                        "escape",
                        [
                            "!echo STOCK_SFTP_ECHO_OK",
                            f"!ls {shlex.quote(str(listed))}",
                            # A local stdin reader must not wait for sftp input.
                            "!cat",
                            f"!cat < {shlex.quote(str(local_input))}",
                            # The a-Shell sh returns 0 for a found command that fails,
                            # so a missing command is the failure it reports.
                            "!stock-sftp-no-such-command",
                            # A bare "!" would start dash, which a worker cannot leave.
                            "!",
                            "pwd",
                        ],
                    )
                ],
                case_dir / "done-escape",
                timeout,
            )
            out, err = read("escape")
            console.print(f"escape: finished={ran}", markup=False)
            if not ran:
                failures.append(f"escape: no exit within {timeout:.0f}s: {err.strip()}")
            # Batch mode echoes each command line, so the output must be a line of its own.
            if "STOCK_SFTP_ECHO_OK" not in out.splitlines():
                failures.append(
                    f"escape: echo output missing from stdout: {err.strip()}"
                )
            if REDIRECTED not in out.splitlines():
                failures.append(
                    "escape: explicitly redirected input missing from stdout"
                )
            if not re.search(r"^Shell exited with status [1-9]", err, re.MULTILINE):
                failures.append(
                    f"escape: no exit status for the failed command: {err.strip()}"
                )
            for want, stream, text in (
                (NO_SHELL, "stderr", err),
                (LISTED, "stdout", out),
                (REMOTE, "stdout", out),
            ):
                if want not in text:
                    failures.append(
                        f"escape: {want!r} missing from {stream}: {err.strip()}"
                    )

            with worker_limit(simulator, bundle_id, BUSY_LIMIT):
                ran = run_profile(
                    simulator,
                    bundle_id,
                    documents,
                    [sftp("busy", ["!echo STOCK_SFTP_BUSY_RAN", "pwd"])],
                    case_dir / "done-busy",
                    timeout,
                )
            out, err = read("busy")
            console.print(f"busy: finished={ran}", markup=False)
            if not ran:
                failures.append(f"busy: no exit within {timeout:.0f}s: {err.strip()}")
            if "STOCK_SFTP_BUSY_RAN" in out.splitlines():
                failures.append("busy: the command ran past the worker limit")
            if "all shell workers are in use" not in err:
                failures.append(f"busy: no worker error on stderr: {err.strip()}")
            if REMOTE not in out:
                failures.append(f"busy: sftp did not continue: {err.strip()}")
            if failures:
                raise RuntimeError("\n".join(failures))
        print("STOCK_SFTP_SHELL_ESCAPE_PASS")
    except KeyboardInterrupt:
        raise typer.Exit(130) from None
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        console.print(str(error), markup=False, highlight=False)
        raise typer.Exit(1) from None


if __name__ == "__main__":
    typer.run(main)
