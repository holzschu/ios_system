#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["typer", "rich"]
# ///
"""Run Stock sftp local shell escapes in a worker-enabled a-Shell host on an iOS Simulator."""

import getpass
import os
import re
import shlex
import shutil
import signal
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


def interactive_controls(simulator, bundle_id, documents, case_dir, config, timeout):
    """Send real terminal keys and use the SFTP transcript, not the app prompt."""
    device = str(simulator).upper()
    stop = ["xcrun", "simctl", "terminate", device, bundle_id]

    def key(*args):
        subprocess.run(
            ["axe", *args, "--udid", device],
            check=True,
            timeout=15,
            capture_output=True,
        )

    def line(command):
        key("type", command + "\n", "--layout", "us")

    def text(path):
        return path.read_text(errors="replace") if path.is_file() else ""

    def wait_for(probe):
        deadline = time.monotonic() + min(timeout, 12)
        while time.monotonic() < deadline:
            if probe():
                return True
            time.sleep(0.3)
        return False

    def terminal_ready():
        ui = subprocess.run(
            ["axe", "describe-ui", "--udid", device],
            check=False,
            capture_output=True,
            timeout=8,
        )
        return ui.returncode == 0 and b'"AXTextArea"' in ui.stdout

    def worker_pid(prefix, match=""):
        logs = simctl(
            "spawn",
            device,
            "log",
            "show",
            "--last",
            "25s",
            "--style",
            "compact",
            "--predicate",
            f'process BEGINSWITH "ShellWorker" AND eventMessage BEGINSWITH "command = {prefix}"',
            capture_output=True,
            text=True,
        )
        rows = "\n".join(line for line in logs.stdout.splitlines() if match in line)
        pids = re.findall(r"ShellWorker[A-J]\[(\d+):", rows)
        return int(pids[-1]) if pids else None

    def worker_gone(pid):
        try:
            os.kill(pid, 0)
        except ProcessLookupError:
            return True
        return False

    failures = []
    with preserved(documents / ".profile"):
        (documents / ".profile").write_text("")
        for name, escape, hid in (
            ("interrupt", "!sleep 37", "6"),
            ("eof", "!cat", "7"),
            ("eof-again", "!cat", "7"),
            ("eof-no-newline", "!cat", "7"),
            ("eof-typeahead", "!cat", "7"),
            ("idle-interrupt", None, "6"),
            ("idle-eof", None, "7"),
            ("stalled-interrupt", None, "6"),
            ("batch-stdin-eof", None, "7"),
        ):
            subprocess.run(stop, check=False, capture_output=True)
            simctl("launch", device, bundle_id, capture_output=True)
            out, err = case_dir / f"{name}.out", case_dir / f"{name}.err"
            # Use a file marker to prove terminal input is focused before SFTP.
            # File paths typed at the prompt are relative to Documents.
            cwd = case_dir.name
            startup = case_dir / f"{name}.ready"
            if not wait_for(terminal_ready):
                raise RuntimeError(f"{name}: terminal UI did not start")
            line(f"echo READY > {cwd}/{startup.name}")
            if not wait_for(lambda startup=startup: text(startup).strip() == "READY"):
                raise RuntimeError(f"{name}: a-Shell startup marker missing")
            batch = "-b - " if name == "batch-stdin-eof" else ""
            line(
                f"sftp -F {cwd}/{config.name} {batch}target > {cwd}/{out.name} 2> {cwd}/{err.name}"
            )
            # Batch mode deliberately suppresses the connection banner.
            if not batch and not wait_for(
                lambda err=err: "Connected to target" in text(err)
            ):
                raise RuntimeError(f"{name}: no SFTP connection: {text(err)}")
            if escape == "!sleep 37":
                line(escape)
                if not wait_for(lambda: worker_pid("sleep 37 pid=")):
                    raise RuntimeError("interrupt: local worker never started sleep")
            elif escape == "!cat":
                typed = case_dir / f"{name}.typed"
                submitted_line = name in {"eof", "eof-again"}
                options = " -u" if submitted_line else ""
                line(f"!cat{options} > {cwd}/{typed.name}")
                if not wait_for(typed.exists):
                    raise RuntimeError(
                        f"{name}: local worker did not open cat's output"
                    )
                payload = "STOCK_SFTP_TYPED_INPUT"
                if submitted_line:
                    payload += "\n"
                key("type", payload, "--layout", "us")
                # AXe's last Return can be delivered after the next Ctrl-D.
                # Establish that the line was submitted; the other cases test
                # a cooked partial line and input immediately after EOF.
                if submitted_line and not wait_for(
                    lambda typed=typed, payload=payload: text(typed) == payload
                ):
                    raise RuntimeError(
                        f"{name}: submitted line never reached cat: {text(typed)!r}"
                    )
            if batch:
                line("pwd")
                if not wait_for(lambda out=out: REMOTE in text(out)):
                    raise RuntimeError(
                        f"{name}: SFTP did not read pwd from batch stdin"
                    )
            if name == "stalled-interrupt":
                line("!sleep 51")
                if not wait_for(lambda: worker_pid("sleep 51 pid=")):
                    raise RuntimeError("stalled-interrupt: local escape did not start")
                pid = worker_pid("", rf"'\134sftp' '-F' '{cwd}/{config.name}'")
                if pid is None:
                    raise RuntimeError(
                        "stalled-interrupt: fixture SFTP worker not found"
                    )
                os.kill(pid, signal.SIGSTOP)
                try:
                    key("key-combo", "--modifiers", "224", "--key", hid)
                    # Hold the XPC receiver beyond the app's one-second deadline.
                    time.sleep(2)
                finally:
                    if not worker_gone(pid):
                        os.kill(pid, signal.SIGCONT)
                if not wait_for(lambda pid=pid: worker_gone(pid)):
                    failures.append(
                        "stalled-interrupt: no cancellation after missing reply"
                    )
                    continue
            else:
                key("key-combo", "--modifiers", "224", "--key", hid)
            if escape:
                if name == "eof-typeahead":
                    line("pwd")
                # Otherwise confirm the escape finished before sending pwd.
                if escape == "!cat":
                    finished = wait_for(
                        lambda typed=typed, payload=payload: text(typed) == payload
                    )
                else:
                    finished = wait_for(
                        lambda err=err: "Shell exited with status 130" in text(err)
                    )
                if name != "eof-typeahead":
                    line("pwd")
                recovered = wait_for(lambda out=out: REMOTE in text(out))
                if not finished or not recovered or "Invalid command" in text(err):
                    received = f", typed={text(typed)!r}" if escape == "!cat" else ""
                    failures.append(
                        f"{name}: no recovery in same SFTP session: {text(out)!r}, {text(err)!r}{received}"
                    )
            else:
                marker = case_dir / f"{name}.local"
                line(f"echo LOCAL > {cwd}/{marker.name}")
                local = wait_for(lambda marker=marker: text(marker).strip() == "LOCAL")
                if not local or "Invalid command" in text(err):
                    failures.append(
                        f"{name}: no clean return to local shell: {text(err)!r}"
                    )
        subprocess.run(stop, check=False, capture_output=True)
    if failures:
        raise RuntimeError("\n".join(failures))


def main(
    simulator: UUID, bundle_id: str, timeout: float = 60.0, controls: bool = False
):
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

            if controls:
                stack.callback(
                    simctl,
                    "terminate",
                    str(simulator),
                    bundle_id,
                    check=False,
                    capture_output=True,
                )
                interactive_controls(
                    simulator, bundle_id, documents, case_dir, config, timeout
                )
                print("STOCK_SFTP_ESCAPE_CONTROLS_PASS")
                return

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
