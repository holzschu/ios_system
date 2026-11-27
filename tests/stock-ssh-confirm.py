#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.12"
# dependencies = ["typer", "rich"]
# ///
"""Exercise the real Stock SSH CLI on an arm64 iOS Simulator."""

import getpass
import os
import plistlib
import secrets
import selectors
import shlex
import shutil
import socket
import subprocess
import tempfile
import time
from contextlib import contextmanager
from pathlib import Path
from typing import Annotated
from uuid import UUID

import typer
from rich.console import Console

HOST = "127.0.0.1"
MARKER = b"STOCK_SSH_CONFIRM_FIXTURE_OK"
REMOTE_COMMAND = f"echo {MARKER.decode()}"
PROMPT = b"Are you sure you want to continue connecting (yes/no/[fingerprint])?"
RETRY_PROMPT = b"Please type 'yes', 'no' or the fingerprint:"
PASSPHRASE_PROMPT = b"Enter passphrase for key"
PASSWORD_PROMPT = b"'s password: "
# PAM keyboard-interactive prompts: "Password: ", "Current password: ", ...
KBDINT_PROMPT = b"assword: "


def prepare_probe(root, runtime_frameworks, stock_frameworks, *, keygen=False):
    frameworks = root / "Frameworks"
    frameworks.mkdir()
    for source, name in (
        (runtime_frameworks, "ios_system"),
        (runtime_frameworks, "openssl"),
        (stock_frameworks, "SSHKeygenStock" if keygen else "SSHStock"),
    ):
        name += ".framework"
        shutil.copytree(source / name, frameworks / name)
    source = Path(__file__).with_suffix(".m")
    probe = root / "stock-ssh-confirm"
    subprocess.run(
        [
            "xcrun",
            "--sdk",
            "iphonesimulator",
            "clang",
            "-target",
            "arm64-apple-ios16.0-simulator",
            "-fobjc-arc",
            "-Wall",
            "-Wextra",
            "-Werror",
            "-F",
            str(frameworks),
            "-framework",
            "ios_system",
            "-framework",
            "Foundation",
            "-Wl,-rpath,@executable_path/Frameworks",
            str(source),
            "-o",
            str(probe),
        ],
        check=True,
    )
    registry = root / "commandDictionary.plist"
    commands = {
        "ssh": [
            "@rpath/SSHStock.framework/SSHStock",
            "ashell_ssh_main",
            "1246ab:c:e:fgi:kl:m:no:p:qstvxAB:CD:E:F:GI:J:KL:MNO:PQ:R:S:TVw:W:XYy",
            "no",
        ],
    }
    if keygen:
        commands = {
            "ssh-keygen": [
                "@rpath/SSHKeygenStock.framework/SSHKeygenStock",
                "ashell_ssh_keygen_main",
                "",
                "no",
            ]
        }
    registry.write_bytes(plistlib.dumps(commands))
    return probe, registry


def key_fields(path):
    return path.read_bytes().split()[:2]


def fingerprint(path):
    return subprocess.check_output(["/usr/bin/ssh-keygen", "-lf", path]).split()[1]


@contextmanager
def loopback_server(root):
    host_key = root / "host-key"
    identity = root / "identity"
    encrypted = root / "encrypted"
    encrypted_next = root / "encrypted-next"
    passphrase = secrets.token_hex(16)
    for key, phrase in (
        (host_key, ""),
        (identity, ""),
        (encrypted, passphrase),
        (encrypted_next, passphrase),
    ):
        subprocess.run(
            ["/usr/bin/ssh-keygen", "-qt", "ed25519", "-N", phrase, "-f", key],
            check=True,
        )
    identity_pub = identity.with_suffix(".pub")
    authorized = root / "authorized_keys"
    authorized.write_bytes(
        identity_pub.read_bytes()
        + encrypted.with_suffix(".pub").read_bytes()
        + encrypted_next.with_suffix(".pub").read_bytes()
    )
    host_pub = host_key.with_suffix(".pub")
    user = getpass.getuser()
    # Reserve an ephemeral port until just before sshd binds it.
    with socket.socket() as reserve:
        reserve.bind((HOST, 0))
        port = reserve.getsockname()[1]
        config = root / "sshd_config"
        config.write_text(f"""\
ListenAddress {HOST}
Port {port}
HostKey "{host_key}"
AuthorizedKeysFile "{authorized}"
AllowUsers {user}
AuthenticationMethods publickey
PasswordAuthentication no
KbdInteractiveAuthentication no
UsePAM no
PerSourcePenalties no
StrictModes no
DisableForwarding yes
PermitTTY no
ForceCommand {REMOTE_COMMAND}
""")

    def host_entry(public_key):
        return f"[{HOST}]:{port} ".encode() + b" ".join(key_fields(public_key)) + b"\n"

    try:
        with (
            (root / "sshd.log").open("wb") as log,
            subprocess.Popen(
                ["/usr/sbin/sshd", "-D", "-e", "-f", config], stderr=log
            ) as server,
        ):
            try:
                deadline = time.monotonic() + 5
                while server.poll() is None:
                    try:
                        with socket.create_connection((HOST, port), timeout=0.1):
                            break
                    except OSError:
                        if time.monotonic() >= deadline:
                            raise RuntimeError(
                                "Timed out waiting for loopback sshd"
                            ) from None
                        time.sleep(0.05)
                else:
                    raise RuntimeError(f"Loopback sshd exited {server.returncode}")
                yield (
                    user,
                    port,
                    identity,
                    host_entry(host_pub),
                    host_entry(identity_pub),
                    fingerprint(host_pub),
                    fingerprint(identity_pub),
                    encrypted,
                    encrypted_next,
                    passphrase.encode(),
                )
            finally:
                if server.poll() is None:
                    server.terminate()
                    try:
                        server.wait(timeout=3)
                    except subprocess.TimeoutExpired:
                        server.kill()
    except RuntimeError as error:
        if str(error).startswith(("Loopback sshd", "Timed out waiting")):
            raise RuntimeError(
                f"{error}: {(root / 'sshd.log').read_text().strip()}"
            ) from None
        raise


def exchange(args, answers, expected_fingerprint, env, prompt=PROMPT):
    with subprocess.Popen(
        args,
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=env,
    ) as client:
        out, err = bytearray(), bytearray()
        sent = consumed = 0
        try:
            if not answers:
                client.stdin.close()
            with selectors.DefaultSelector() as ready:
                ready.register(client.stdout, selectors.EVENT_READ, out)
                ready.register(client.stderr, selectors.EVENT_READ, err)
                deadline = time.monotonic() + 12
                while ready.get_map():
                    left = deadline - time.monotonic()
                    if left <= 0:
                        raise RuntimeError("Simulator SSH command timed out")
                    for key, _ in ready.select(left):
                        data = os.read(key.fd, 8192)
                        if data:
                            key.data.extend(data)
                        else:
                            ready.unregister(key.fileobj)
                    while sent < len(answers):
                        expected = prompt if isinstance(prompt, bytes) else prompt[sent]
                        index = err.find(expected, consumed)
                        if index == -1:
                            break
                        consumed = index + len(expected)
                        if expected_fingerprint is not None:
                            assert expected_fingerprint in err, (
                                "wrong fingerprint in the prompt"
                            )
                        assert expected not in out, "prompt appeared on stdout"
                        client.stdin.write(answers[sent])
                        client.stdin.flush()
                        sent += 1
                        if sent == len(answers):
                            client.stdin.close()
            return client.wait(timeout=2), bytes(out), bytes(err), sent
        finally:
            if client.poll() is None:
                client.kill()


def child_env():
    env = {k: v for k, v in os.environ.items() if not k.startswith("SIMCTL_CHILD_")}
    env["SIMCTL_CHILD_SSH_ASKPASS_REQUIRE"] = "never"
    env["SIMCTL_CHILD_LC_ALL"] = "C"
    return env


def fixture_secret(path):
    secret = path.read_bytes().rstrip(b"\n")
    assert secret and not any(c in secret for c in (b"\r", b"\n", b"\x00"))
    return secret


def check_password_retry(
    simulator, runtime_frameworks, stock_frameworks, fixture, console
):
    # A separately qualified, disposable PAM sshd; never ask for a Mac account password.
    config = fixture / "config"
    secret = fixture_secret(fixture / "password")
    with tempfile.TemporaryDirectory(prefix="stock-ssh-password-") as work:
        root = Path(work)
        probe, registry = prepare_probe(root, runtime_frameworks, stock_frameworks)

        def ssh_args(method, host):
            cmd = shlex.join(
                [
                    "ssh",
                    "-F",
                    str(config.resolve()),
                    "-o",
                    "HostName=127.0.0.1",
                    "-o",
                    "StrictHostKeyChecking=yes",
                    "-o",
                    f"PreferredAuthentications={method}",
                    "-o",
                    "NumberOfPasswordPrompts=2",
                    host,
                    REMOTE_COMMAND,
                ]
            )
            return [
                *("xcrun", "simctl", "spawn", str(simulator)),
                *(probe, registry, root, cmd),
            ]

        args = ssh_args("password", "password-fixture")
        for name, first_ending, second_prefix in (
            ("crlf", b"\r\n", b""),
            ("split-crlf", b"\r", b"\n"),
            ("cr-only", b"\r", b""),
        ):
            status, out, err, sent = exchange(
                args,
                (b"wrong-" + secret + first_ending, second_prefix + secret + b"\r"),
                None,
                child_env(),
                PASSWORD_PROMPT,
            )
            assert secret not in out and secret not in err, f"{name}: password echoed"
            result = (
                status,
                sent,
                err.count(PASSWORD_PROMPT),
                MARKER in out.splitlines(),
            )
            console.print(
                f"password-{name}: status={status} answers={sent} prompts={result[2]} login={result[3]}",
                markup=False,
            )
            assert (
                result == (0, 2, 2, True)
                and b"Permission denied, please try again." in err
            ), f"{name}: wrong-password retry failed"

        # PAM asks through keyboard-interactive, which ssh tries before password by default.
        status, out, err, sent = exchange(
            ssh_args("keyboard-interactive", "password-fixture"),
            (b"wrong-" + secret + b"\r\n", secret + b"\r"),
            None,
            child_env(),
            KBDINT_PROMPT,
        )
        assert secret not in out and secret not in err, "kbdint: password echoed"
        result = (status, sent, err.count(KBDINT_PROMPT), MARKER in out.splitlines())
        console.print(
            f"keyboard-interactive: status={status} answers={sent} prompts={result[2]} login={result[3]}",
            markup=False,
        )
        assert result == (0, 2, 2, True), "keyboard-interactive retry failed"

        # An expired account changes its password inside the same exchange.
        # The change is permanent: reset the fixture before the next run.
        if (fixture / "expired-password").exists():
            old = fixture_secret(fixture / "expired-password")
            new = fixture_secret(fixture / "expired-new-password")
            status, out, err, sent = exchange(
                ssh_args("keyboard-interactive", "expired-fixture"),
                (old + b"\r", old + b"\r\n", new + b"\r", new + b"\r"),
                None,
                child_env(),
                KBDINT_PROMPT,
            )
            assert not any(s in out or s in err for s in (old, new)), (
                "expired: password echoed"
            )
            result = (
                status,
                sent,
                err.count(KBDINT_PROMPT),
                MARKER in out.splitlines(),
            )
            console.print(
                f"expired-password: status={status} answers={sent} prompts={result[2]} login={result[3]}",
                markup=False,
            )
            assert result == (0, 4, 4, True) and b"New password: " in err, (
                "expired password change failed"
            )


def check_confirmation(simulator, runtime_frameworks, stock_frameworks, console):
    with tempfile.TemporaryDirectory(prefix="stock-ssh-confirm-") as work:
        root = Path(work)
        probe, registry = prepare_probe(root, runtime_frameworks, stock_frameworks)
        with loopback_server(root) as fixture:
            (
                user,
                port,
                identity,
                host_entry,
                wrong_entry,
                host_fp,
                wrong_fp,
                encrypted,
                encrypted_next,
                phrase,
            ) = fixture
            base_args = [
                "ssh",
                "-vv",
                "-F",
                "/dev/null",
                "-p",
                str(port),
                "-o",
                "IdentitiesOnly=yes",
                "-o",
                "GlobalKnownHostsFile=/dev/null",
                "-o",
                "ConnectTimeout=5",
            ]
            env = child_env()

            def run(
                name,
                *,
                answer=None,
                prompted=False,
                accept=False,
                reuse=None,
                known=None,
                options=(),
                redirect_stdin=False,
                redirect_stdout=False,
                force_askpass=False,
                warning=None,
                prompt=PROMPT,
                hidden=None,
            ):
                home = reuse or root / name
                key = home / ".ssh" / "known_hosts"
                if reuse is None:
                    key.parent.mkdir(mode=0o700, parents=True)
                    local_identity = key.parent / "id_ed25519"
                    shutil.copyfile(identity, local_identity)
                    local_identity.chmod(0o600)
                    (home / "known_hosts").write_bytes(host_entry)
                    if known is not None:
                        key.write_bytes(known)
                before = key.read_bytes() if key.exists() else None
                cmd = shlex.join(
                    [*base_args, *options, f"{user}@{HOST}", REMOTE_COMMAND]
                )
                if redirect_stdin:
                    reply = home / "stdin"
                    reply.write_bytes(b"yes\n")
                    cmd += f" < {shlex.quote(str(reply))}"
                if redirect_stdout:
                    output = home / "stdout"
                    cmd += f" > {shlex.quote(str(output))}"
                case_env = env
                if force_askpass:
                    case_env = env | {
                        "SIMCTL_CHILD_SSH_ASKPASS_REQUIRE": "force",
                        "SIMCTL_CHILD_SSH_ASKPASS": str(home / "missing-askpass"),
                    }
                args = [
                    "xcrun",
                    "simctl",
                    "spawn",
                    str(simulator),
                    probe,
                    registry,
                    home,
                    cmd,
                ]
                fingerprint_check = host_fp if prompt == PROMPT else None
                status, out, err, sent = exchange(
                    args,
                    () if answer is None else (answer,),
                    fingerprint_check,
                    case_env,
                    prompt,
                )
                if hidden is not None:
                    assert hidden not in out and hidden not in err, (
                        f"{name}: secret was echoed"
                    )
                actual_prompt = prompt in err
                if redirect_stdout:
                    assert not out, f"{name}: command wrote to unredirected stdout"
                    out = output.read_bytes()
                marker = MARKER in out.splitlines()
                expected_status = 0 if accept else 255
                message = f"{name}: status={status} prompt={actual_prompt} answer={sent} login={marker}"
                console.print(message, markup=False)
                assert (status, actual_prompt, sent, marker) == (
                    expected_status,
                    prompted,
                    int(answer is not None),
                    accept,
                ), f"{message}\n{err.decode(errors='replace')[-3000:]}"
                assert (home / "known_hosts").read_bytes() == host_entry, (
                    f"{name}: legacy file changed"
                )
                after = key.read_bytes() if key.exists() else None
                assert after == (host_entry if accept else before), (
                    f"{name}: unexpected Stock trust file"
                )
                if warning is not None:
                    assert warning in err, (
                        f"{name}: expected warning {warning!r} missing"
                    )
                return home

            home = run("yes", answer=b"yes\r", prompted=True, accept=True)
            run("reconnect", reuse=home, accept=True)
            run(
                "encrypted-identity",
                reuse=home,
                options=("-i", str(encrypted)),
                prompt=PASSPHRASE_PROMPT,
                answer=phrase + b"\r",
                prompted=True,
                accept=True,
                hidden=phrase,
            )
            for name, prefix in (("control", b"bad\x01"), ("overflow", b"a" * 1024)):
                run(
                    f"rejected-{name}-before-next-key",
                    reuse=home,
                    options=("-i", str(encrypted), "-i", str(encrypted_next)),
                    prompt=PASSPHRASE_PROMPT,
                    answer=prefix + phrase + b"\r\n",
                    prompted=True,
                    hidden=phrase,
                    warning=f"Enter passphrase for key '{str(encrypted_next)[:100]}'".encode(),
                )
            run(
                "encrypted-identity-incomplete",
                reuse=home,
                options=("-i", str(encrypted)),
                prompt=PASSPHRASE_PROMPT,
                answer=phrase,
                prompted=True,
                hidden=phrase,
            )
            run(
                "encrypted-identity-redirected",
                reuse=home,
                options=("-i", str(encrypted)),
                prompt=PASSPHRASE_PROMPT,
                redirect_stdin=True,
            )
            run(
                "encrypted-identity-forced-askpass",
                reuse=home,
                options=("-i", str(encrypted)),
                prompt=PASSPHRASE_PROMPT,
                force_askpass=True,
                warning=b"read_passphrase: requested to askpass",
            )
            run(
                "stdout-file",
                answer=b"yes\r",
                prompted=True,
                accept=True,
                redirect_stdout=True,
            )
            run(
                "forced-askpass",
                force_askpass=True,
                warning=b"read_passphrase: requested to askpass",
            )
            run("exact-fingerprint", answer=host_fp + b"\n", prompted=True, accept=True)
            run(
                "wrong-fingerprint",
                answer=wrong_fp + b"\n",
                prompted=True,
                warning=RETRY_PROMPT,
            )
            run("no", answer=b"no\n", prompted=True)
            run("eof-without-newline", answer=b"yes", prompted=True)
            run("nul-input", answer=b"yes\x00\r", prompted=True)
            run("redirected-yes", redirect_stdin=True)
            run("batch", options=("-o", "BatchMode=yes"))
            run("strict", options=("-o", "StrictHostKeyChecking=yes"))
            run(
                "changed-key",
                known=wrong_entry,
                warning=b"REMOTE HOST IDENTIFICATION HAS CHANGED",
            )
    print("STOCK_SSH_CONFIRMATION_PASS")


def check_keygen(simulator, runtime_frameworks, stock_frameworks, console):
    with tempfile.TemporaryDirectory(prefix="stock-ssh-keygen-") as work:
        root = Path(work)
        probe, registry = prepare_probe(
            root, runtime_frameworks, stock_frameworks, keygen=True
        )
        key = root / "key"
        generated = root / "generated"
        old, new = (secrets.token_hex(16).encode() for _ in range(2))
        subprocess.run(
            ["/usr/bin/ssh-keygen", "-qt", "ed25519", "-N", old, "-f", key],
            check=True,
        )
        before = key.read_bytes()
        public = key_fields(key.with_suffix(".pub"))
        first = b"(empty for no passphrase): "
        again = b"Enter same passphrase again:"
        change = (b"Enter old passphrase:", b"Enter new passphrase", again)

        def run(name, options, prompts=(), answers=(), *, check):
            args = [
                "xcrun",
                "simctl",
                "spawn",
                str(simulator),
                probe,
                registry,
                root,
                shlex.join(["ssh-keygen", *options]),
            ]
            try:
                status, out, err, sent = exchange(
                    args, answers, None, child_env(), prompts
                )
            except RuntimeError as error:
                raise RuntimeError(f"{name}: {error}") from error
            assert not any(s in out or s in err for s in (old, new)), (
                f"{name}: secret echoed"
            )
            passed = sent == len(answers) and check(status, out, err)
            console.print(
                f"{name}: status={status} answers={sent}/{len(answers)} {'PASS' if passed else 'FAIL'}"
            )
            return passed

        def unlocked_with(path, phrase):
            result = subprocess.run(
                ["/usr/bin/ssh-keygen", "-y", "-P", phrase, "-f", path],
                capture_output=True,
                check=False,
            )
            return result.returncode == 0 and result.stdout.split()[:2] == key_fields(
                path.with_suffix(".pub")
            )

        creation = run(
            "create-encrypted",
            ("-qt", "ed25519", "-f", str(generated)),
            (first, again),
            (new + b"\r\n", new + b"\r"),
            check=lambda status, *_: (
                status == 0
                and unlocked_with(generated, new)
                and not unlocked_with(generated, b"")
            ),
        )
        public_read = run(
            "read-encrypted-public",
            ("-y", "-f", str(key)),
            (b"Enter passphrase for",),
            (old + b"\r",),
            check=lambda status, out, _: status == 0 and out.split()[:2] == public,
        )
        aborted = run(
            "incomplete-change",
            ("-p", "-f", str(key)),
            change[:2],
            (old + b"\r", new),
            check=lambda status, _, err: (
                status != 0 and again not in err and key.read_bytes() == before
            ),
        )
        changed = run(
            "change-passphrase",
            ("-p", "-f", str(key)),
            change,
            (old + b"\r", new + b"\r", new + b"\r"),
            check=lambda status, *_: (
                status == 0 and unlocked_with(key, new) and not unlocked_with(key, old)
            ),
        )
        comment = run(
            "change-comment",
            ("-c", "-C", "fixture-comment", "-f", str(key)),
            (b"Enter passphrase:",),
            (new + b"\r",),
            check=lambda status, *_: (
                status == 0
                and key.with_suffix(".pub")
                .read_bytes()
                .rstrip()
                .endswith(b" fixture-comment")
            ),
        )
        message = root / "message"
        message.write_bytes(b"Stock SSH signing fixture\n")
        signature = message.with_suffix(".sig")

        def signature_valid(status, *_):
            if status != 0 or not signature.exists():
                return False
            return (
                subprocess.run(
                    [
                        "/usr/bin/ssh-keygen",
                        "-Y",
                        "check-novalidate",
                        "-n",
                        "file",
                        "-s",
                        signature,
                    ],
                    input=message.read_bytes(),
                    capture_output=True,
                    check=False,
                ).returncode
                == 0
            )

        signed = run(
            "sign-file",
            ("-Y", "sign", "-n", "file", "-f", str(key), str(message)),
            (b"Enter passphrase for",),
            (new + b"\r",),
            check=signature_valid,
        )
        subject = root / "subject"
        subprocess.run(
            ["/usr/bin/ssh-keygen", "-qt", "ed25519", "-N", "", "-f", subject],
            check=True,
        )
        certified = run(
            "sign-certificate",
            ("-s", str(key), "-I", "fixture-id", str(subject.with_suffix(".pub"))),
            (b"Enter passphrase for",),
            (new + b"\r",),
            check=lambda status, *_: (
                status == 0
                and b'Key ID: "fixture-id"'
                in subprocess.check_output(
                    ["/usr/bin/ssh-keygen", "-L", "-f", root / "subject-cert.pub"],
                )
            ),
        )
        empty = root / "empty"
        no_secret = run(
            "explicit-empty",
            ("-qt", "ed25519", "-f", str(empty)),
            (first, again),
            (b"\r", b"\r"),
            check=lambda status, *_: status == 0 and unlocked_with(empty, b""),
        )
        refused = root / "refused"
        no_key = run(
            "missing-input",
            ("-qt", "ed25519", "-f", str(refused)),
            check=lambda status, _, err: (
                status != 0
                and b"Could not read passphrase" in err
                and not refused.exists()
                and not refused.with_suffix(".pub").exists()
            ),
        )
        assert all(
            (
                creation,
                public_read,
                aborted,
                changed,
                comment,
                signed,
                certified,
                no_secret,
                no_key,
            )
        ), "Stock ssh-keygen passphrase regression"
    print("STOCK_SSH_KEYGEN_PASSPHRASE_PASS")


def main(
    simulator: UUID,
    runtime_frameworks: Path,
    stock_frameworks: Path,
    password_fixture: Annotated[
        Path | None,
        typer.Option(
            help="Disposable loopback sshd: directory with config and password files."
        ),
    ] = None,
    keygen_only: Annotated[
        bool, typer.Option(help="Check Stock ssh-keygen passphrases only.")
    ] = False,
):
    """Run against a booted Simulator; supply runtime inputs and the recipe's sdk directory."""
    console = Console(stderr=True)
    try:
        if keygen_only:
            check_keygen(simulator, runtime_frameworks, stock_frameworks, console)
            return
        if password_fixture is not None:
            check_password_retry(
                simulator,
                runtime_frameworks,
                stock_frameworks,
                password_fixture,
                console,
            )
        check_confirmation(simulator, runtime_frameworks, stock_frameworks, console)
    except KeyboardInterrupt:
        raise typer.Exit(130) from None
    except (AssertionError, OSError, RuntimeError, subprocess.SubprocessError) as error:
        console.print(str(error), markup=False, highlight=False)
        raise typer.Exit(1) from None


if __name__ == "__main__":
    typer.run(main)
