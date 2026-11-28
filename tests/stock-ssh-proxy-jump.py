#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["typer", "rich"]
# ///
"""Run Stock SSH ProxyJump in a worker-enabled a-Shell host on an iOS Simulator."""

import getpass
import shlex
import shutil
import socket
import subprocess
import tempfile
import time
from contextlib import ExitStack, contextmanager
from pathlib import Path
from typing import Annotated
from uuid import UUID

import typer
from rich.console import Console

HOST = "127.0.0.1"
MARKER = "STOCK_SSH_JUMP_FIXTURE_OK"
HOPS = ("hop1", "hop2", "hop3")
# A failed hop must end as promptly as on macOS; without ConnectTimeout a leaked
# stream used to keep the outer client waiting forever.
FAILURE_BOUND = 10.0


def simctl(*args, **kwargs):
    return subprocess.run(["xcrun", "simctl", *args], check=True, **kwargs)


def free_ports(count):
    sockets = [socket.socket() for _ in range(count)]
    try:
        for s in sockets:
            s.bind((HOST, 0))
        return [s.getsockname()[1] for s in sockets]
    finally:
        for s in sockets:
            s.close()


@contextmanager
def sshd(root, name, port, client_pub, extra):
    key = root / f"host-{name}"
    subprocess.run(
        ["/usr/bin/ssh-keygen", "-qt", "ed25519", "-N", "", "-f", key], check=True
    )
    config = root / f"{name}.conf"
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
PermitTTY no
{extra}""")
    with (
        (root / f"{name}.log").open("wb") as log,
        subprocess.Popen(
            ["/usr/sbin/sshd", "-D", "-e", "-f", config], stderr=log
        ) as server,
    ):
        try:
            deadline = time.monotonic() + 5
            while True:
                if server.poll() is not None:
                    raise RuntimeError(
                        f"{name} sshd exited {server.returncode}: "
                        + (root / f"{name}.log").read_text().strip()
                    )
                try:
                    with socket.create_connection((HOST, port), timeout=0.1):
                        break
                except OSError:
                    if time.monotonic() >= deadline:
                        raise RuntimeError(f"Timed out waiting for {name} sshd")
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


def check_password_jump(simulator, bundle_id, documents, fixture, console, hosts):
    case = "two-password-jump" if len(hosts) == 2 else "three-password-jump"
    prompt_suffix = b"'s password: "
    secrets = [(fixture / name).read_bytes().rstrip(b"\n") for name in hosts]
    if any(len(secret) < 12 or not secret.isalnum() for secret in secrets):
        raise RuntimeError(
            "Use alphanumeric fixture passwords of at least 12 characters"
        )
    if len(set(secrets)) != len(hosts):
        raise RuntimeError("Each jump and the target must have a different password")
    # AXe matches the simulator UDID as printed by simctl, not UUID's lowercase form.
    device = str(simulator).upper()
    stop = ["xcrun", "simctl", "terminate", device, bundle_id]

    def type_line(value):
        subprocess.run(
            ["axe", "type", "--stdin", "--layout", "us", "--udid", device],
            input=value,
            capture_output=True,
            check=True,
            timeout=30,
        )
        subprocess.run(
            ["axe", "key", "40", "--udid", device],
            capture_output=True,
            check=True,
            timeout=10,
        )

    def read(path):
        try:
            return path.read_bytes()
        except FileNotFoundError:
            return b""

    profile = documents / ".profile"
    with (
        tempfile.TemporaryDirectory(
            prefix="stock-ssh-password-", dir=documents
        ) as work,
        preserved(profile),
    ):
        root = Path(work)
        config = root / "config"
        config.write_text(
            (fixture / "config").read_text().replace("@FIXTURE@", str(root))
        )
        shutil.copyfile(fixture / "known_hosts", root / "known_hosts")
        out, err = root / "out", root / "err"
        command = shlex.join(
            [
                "ssh",
                "-v",
                "-F",
                str(config),
                "-J",
                ",".join(hosts[:-1]),
                hosts[-1],
                "echo",
                MARKER,
            ]
        )
        # A launch PID can precede the terminal's keyboard/input setup.
        ready = root / "ready"
        profile.write_text(f"echo ready > {shlex.quote(str(ready))}\n")
        simctl("launch", device, bundle_id, capture_output=True)
        try:
            deadline = time.monotonic() + 15
            while not ready.is_file():
                if time.monotonic() >= deadline:
                    raise RuntimeError(
                        "Timed out waiting for the password test terminal"
                    )
                time.sleep(0.1)
            type_line(
                f"{command} > {shlex.quote(str(out))} 2> {shlex.quote(str(err))}".encode()
            )
            answered = 0
            seen = 0
            denied = False
            status_ok = False
            deadline = time.monotonic() + 20
            while time.monotonic() < deadline:
                stderr = read(err)
                seen = stderr.count(prompt_suffix)
                denied = b"Permission denied (" in stderr
                status_ok = b"debug1: Exit status 0" in stderr
                if denied or status_ok:
                    break
                if seen > answered:
                    prompt = stderr.splitlines()[-1]
                    if (
                        seen != answered + 1
                        or answered == len(hosts)
                        or not prompt.endswith(
                            f"@{hosts[answered]}'s password: ".encode()
                        )
                    ):
                        break
                    type_line(secrets[answered])
                    answered += 1
                time.sleep(0.1)
            stdout, stderr = read(out), read(err)
            login = MARKER.encode() in stdout.splitlines()
            echoed = any(secret in stdout or secret in stderr for secret in secrets)
            passed = (
                status_ok
                and login
                and not echoed
                and answered == seen == len(hosts)
                and prompt_suffix not in stdout
            )
            status = (
                "0"
                if status_ok
                else "permission denied"
                if denied
                else "incomplete"
                if err.exists()
                else "command not started"
            )
            console.print(
                f"{case}: status={status} prompts={seen} "
                f"answers={answered} echoed={echoed} login={login}",
                markup=False,
            )
            if not passed:
                raise RuntimeError(
                    "Expected ordered hop and target prompts, a successful login, "
                    "and no passwords in the output streams"
                )

            if len(hosts) > 2:
                return

            # A custom proxy must not use the foreground authentication input.
            proxy = shlex.join(
                ["ssh", "-v", "-F", str(config), "-W", "%h:%p", hosts[0]]
            )
            command = shlex.join(
                [
                    "ssh",
                    "-v",
                    "-F",
                    str(config),
                    "-o",
                    f"ProxyCommand={proxy}",
                    hosts[-1],
                    "echo",
                    MARKER,
                ]
            )
            out, err = root / "proxy-out", root / "proxy-err"
            type_line(
                f"{command} > {shlex.quote(str(out))} 2> {shlex.quote(str(err))}".encode()
            )
            deadline = time.monotonic() + 15
            while time.monotonic() < deadline:
                stdout, stderr = read(out), read(err)
                if prompt_suffix in stdout or prompt_suffix in stderr:
                    raise RuntimeError("Custom ProxyCommand unexpectedly prompted")
                if b"Permission denied (password)." in stderr:
                    break
                time.sleep(0.1)
            else:
                raise RuntimeError("Expected password refusal from custom ProxyCommand")
            console.print("password-proxy-command: permission denied, no prompt")
        finally:
            subprocess.run(stop, check=False, capture_output=True)


def main(
    simulator: UUID,
    bundle_id: str,
    timeout: float = 120.0,
    password_fixture: Annotated[
        Path | None,
        typer.Option(
            help="Disposable password fixture; requires AXe and a focused terminal."
        ),
    ] = None,
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
            tempfile.TemporaryDirectory(prefix="stock-ssh-proxy-jump-") as work,
            ExitStack() as stack,
        ):
            root = Path(work)
            client = root / "client"
            subprocess.run(
                ["/usr/bin/ssh-keygen", "-qt", "ed25519", "-N", "", "-f", client],
                check=True,
            )
            ports = dict(zip((*HOPS, "target"), free_ports(4)))
            allowed = " ".join(f"{HOST}:{p}" for p in ports.values())
            host_keys = {
                name: stack.enter_context(
                    sshd(
                        root,
                        name,
                        port,
                        client.with_suffix(".pub"),
                        f"AllowTcpForwarding local\nPermitOpen {allowed}\nForceCommand /usr/bin/false\n"
                        if name != "target"
                        else f"DisableForwarding yes\nForceCommand echo {MARKER}\n",
                    )
                )
                for name, port in ports.items()
            }
            case_dir = documents / f"stock-ssh-proxy-jump-{time.time_ns()}"
            case_dir.mkdir()
            stack.callback(shutil.rmtree, case_dir, ignore_errors=True)
            (case_dir / "client").write_bytes(client.read_bytes())
            (case_dir / "client").chmod(0o600)
            known = case_dir / "known_hosts"
            known.write_text(
                "".join(
                    f"[{HOST}]:{ports[n]} "
                    + " ".join(host_keys[n].read_text().split()[:2])
                    + "\n"
                    for n in ports
                )
            )
            config = case_dir / "config"
            # No ConnectTimeout: a failed hop must end on its own.
            config.write_text(
                "".join(
                    f"Host {n}\n  HostName {HOST}\n  Port {ports[n]}\n  User {getpass.getuser()}\n"
                    f"  IdentityFile {case_dir / 'client'}\n  IdentitiesOnly yes\n"
                    f"  UserKnownHostsFile {known}\n  StrictHostKeyChecking yes\n  BatchMode yes\n"
                    for n in ports
                )
            )
            cases = [
                ("jump1", ["-J", "hop1", "target"]),
                ("jump2", ["-J", "hop1,hop2", "target"]),
                ("jump3", ["-J", ",".join(HOPS), "target"]),
                (
                    "proxy-command",
                    ["-o", f"ProxyCommand=ssh -F {config} -W %h:%p hop1", "target"],
                ),
                # hop1 refuses to forward to port 1.
                ("dead-hop", ["-J", "hop1", "-p", "1", f"{getpass.getuser()}@{HOST}"]),
                ("after-dead", ["-J", "hop1", "target"]),
            ]
            profile = documents / ".profile"
            stack.enter_context(preserved(profile))
            done = case_dir / "done"
            profile.write_text(
                "".join(
                    shlex.join(["ssh", "-F", str(config), *args])
                    + f" > {shlex.quote(str(case_dir / name))}.out"
                    + f" 2> {shlex.quote(str(case_dir / name))}.err\n"
                    for name, args in cases
                )
                + f"echo done > {shlex.quote(str(done))}\n"
            )
            stop = ["xcrun", "simctl", "terminate", str(simulator), bundle_id]
            subprocess.run(stop, check=False, capture_output=True)
            simctl("launch", str(simulator), bundle_id, capture_output=True)
            stack.callback(subprocess.run, stop, check=False, capture_output=True)
            deadline = time.monotonic() + timeout
            while not done.exists():
                if time.monotonic() >= deadline:
                    started = [n for n, _ in cases if (case_dir / f"{n}.err").exists()]
                    raise RuntimeError(
                        f"Timed out after {timeout:.0f}s; last case started: {started[-1] if started else 'none'}"
                    )
                time.sleep(0.5)
            failures = []
            starts = [(case_dir / f"{n}.err").stat().st_birthtime for n, _ in cases]
            starts.append(done.stat().st_birthtime)
            for i, (name, _) in enumerate(cases):
                out = (case_dir / f"{name}.out").read_text(errors="replace")
                err = (case_dir / f"{name}.err").read_text(errors="replace")
                took = starts[i + 1] - starts[i]
                login = MARKER in out.splitlines()
                console.print(f"{name}: {took:.1f}s login={login}", markup=False)
                if name == "dead-hop":
                    if (
                        login
                        or took > FAILURE_BOUND
                        or "stdio forwarding failed" not in err
                    ):
                        failures.append(
                            f"{name}: took {took:.1f}s login={login}: {err.strip()}"
                        )
                elif not login:
                    failures.append(f"{name}: no login: {err.strip()}")
            if failures:
                raise RuntimeError("\n".join(failures))
        if password_fixture is not None:
            if (password_fixture / "password-hop2").is_file():
                check_password_jump(
                    simulator,
                    bundle_id,
                    documents,
                    password_fixture,
                    console,
                    ("password-hop", "password-hop2", "password-target"),
                )
            check_password_jump(
                simulator,
                bundle_id,
                documents,
                password_fixture,
                console,
                ("password-hop", "password-target"),
            )
        print("STOCK_SSH_PROXY_JUMP_PASS")
    except KeyboardInterrupt:
        raise typer.Exit(130) from None
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        console.print(str(error), markup=False, highlight=False)
        raise typer.Exit(1) from None


if __name__ == "__main__":
    typer.run(main)
