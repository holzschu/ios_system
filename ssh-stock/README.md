# Stock OpenSSH clients

Builds on a-shell#1089 and holzschu/ios_system#201. The application worker foundation must provide nested isolated spawn with terminal selection and separate stderr. The qualified generic foundation includes that follow-up and explicit root identities.

This recipe builds OpenSSH 10.6p1 ssh, ssh-keygen, scp and sftp from the verified portable release archive. The adapter uses ios_system command streams and its isolated spawn API for child SSH commands. The application opts the stock client commands into `ASHELL_WORKER_COMMANDS`. Each opted-in invocation needs a fresh extension process; missing worker APIs or worker exhaustion return status 127 instead of running these programs in a shared thread. The application must set ASHELL_WORKER_ROOT_PID to its reserved ios_system PID before executing a worker root command.

After each remote-source SCP transfer, the adapter waits for the SSH child and checks its exit status before starting the next source. This uses the same wait/status handling as stock SCP's remote-to-remote SFTP path and keeps sequential transfers within one child-worker reservation.

Download https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.6p1.tar.gz into INPUTS, then run:

```sh
bash ssh-stock/build.sh iphonesimulator INPUTS FRESH_OUTPUT VERIFIED_FRAMEWORKS
```

Use iphoneos for device frameworks. VERIFIED_FRAMEWORKS contains matching ios_system.framework and openssl.framework inputs. The output contains four unsigned frameworks and source/toolchain/input receipts. Signing, embedding the frameworks and command registration belong to the application.

The build checks each binary's imports against the selected SDK stubs and the supplied `ios_system` and `openssl` framework exports. It also rejects the `___progname` import or export that App Store Connect flagged in #203, even if the SDK exports it. To audit an existing binary, run `bash ssh-stock/audit-symbols.sh SDK ARCH STOCK_BINARY VERIFIED_FRAMEWORKS` for each slice. The SDK check does not replace App Store validation.

When opening `/dev/tty` fails with `ENXIO` or the worker sandbox denies it with `EPERM`, Stock `ssh` can show the host-key confirmation on the a-Shell terminal and read the reply there. Use these client frameworks with the matching ios_system runtime, which preserves the distinction between terminal input and a pipe when starting the SSH worker. Existing host keys are still checked by OpenSSH, and the legacy `$SSH_HOME/known_hosts` file is not imported.

Stock `ssh-keygen` reads passphrases from the echo-free foreground terminal. Press Return at both prompts to choose an empty passphrase; EOF or rejected input aborts instead of saving an unencrypted key. Use the existing `-N` and `-P` options for noninteractive input. The Simulator regression is `tests/stock-ssh-confirm.py SIMULATOR VERIFIED_FRAMEWORKS OUTPUT/sdk --keygen-only`.

Stock `scp` and `sftp` lend virtual terminal input to their Stock SSH child over the worker broker. The child reads authentication answers from that separate stream; its stdin/stdout remain the transfer protocol. This requires the matching app worker broker as well as the client frameworks and ios_system runtime. Redirected stdin and SSH `BatchMode` do not make a secret prompt available.

For the Simulator check, install the paired app and frameworks, activate Stock clients, and focus the app terminal in Documents. Use a disposable SSH server with `/fixture/payload`, a known host key, password authentication, and both an encrypted and an unencrypted identity. In `Documents/stock-transfer/config`, configure `stockpw`, `stockkey`, and `stockcontrol` with strict known-host checking and respectively password-only, encrypted-key-only, and unencrypted-key-only authentication. In `Documents/stock-transfer/batch`, put `get /fixture/payload stock-transfer/sftp-batch.recv` followed by `bye`. With the synthetic answers and the expected `payload` in `FIXTURE/{password,phrase,payload}`, run `bash tests/stock-transfer-prompts.sh SIMULATOR FIXTURE`. Before rerunning, move the previous `.out`, `.err`, and `.recv` files out of `Documents/stock-transfer`; keep its config, keys, and batch file. The driver retains its outputs there and refuses stale files. It checks prompts, that answers are absent from captured stdout and stderr, exact payloads, and noninteractive controls through the app's actual Stock commands.

Strict POSIX spawn remains extension-only.

`ProxyJump` (`-J`) and `ProxyCommand` run their proxy in a separate worker connected to `ssh` by one socket, since `fork` is unavailable. Each `-J` hop runs its own `ssh` as a worker root, so n hops need n + 1 workers in total. The host app sizes the pool; a-Shell allows one worker per physical core by default, up to its 10 bundled worker extensions, and each other open pane also holds a worker. With too few free workers the client fails with `proxy spawn failed: No space left on device`. A `ProxyCommand` runs through `sh -c` without the usual `exec` prefix, because the a-Shell `sh` has no `exec` builtin. When a hop fails, `ssh` closes its channel descriptors at exit, so the caller sees EOF at once instead of hanging, or waiting for `ConnectTimeout` if one is set. Built-in `-J` hops can read authentication answers through the separate foreground terminal input used by Stock SCP and SFTP. Each jump worker passes that input to the next worker it spawns for the chain. The workers still use their sockets for the SSH protocol; redirected stdin does not provide terminal input. This requires a host app that supports passing the terminal descriptor to its workers. Custom `ProxyCommand` workers are unchanged. See [the ProxyJump test](../tests/README.md#stock-ssh-proxyjump).

The recipe retains the supplied OpenSSL version. The tested input was OpenSSL 1.1.1w; updating that dependency is separate work.

With a disposable SSH host and identity, the public CLI check runs as:

```sh
dash ssh-stock/phone-client.sh ABSOLUTE_NEW_CASE_DIRECTORY HOST PORT USER IDENTITY KNOWN_HOSTS
```

The check covers Ed25519 generation/readback, strict key login and byte-identical scp/sftp transfers, including multiple remote SCP sources in one invocation, a missing source returning a nonzero status while a later source still transfers, and a successful login afterward. Phone qualification on 2026-10-23 passed the original transfer fixture with the production worker correction. The later multi-source SCP regression first exhausted a three-worker Simulator pool, then passed through the same SSH caller with the same three-worker capacity after the transport-wait correction. A preserved identity, SSH config and known_hosts created by the old 8.5 build also passed strict login. These results qualify the integrated worker build; these phone results do not qualify later public-source revisions.

Run `dash ssh-stock/home-migration.sh CASE_DIR HOST PORT USER THROWAWAY_IDENTITY KNOWN_HOSTS` through the app to verify default config, Ed25519 identity and strict known_hosts lookup using `SSH_HOME/.ssh`, without `-F`, `-i` or `UserKnownHostsFile`. The adapter uses the existing app `SSH_HOME` root (Documents by default), falling back to HOME when that override is absent. Keep CASE_DIR fresh; the fixture retains its throwaway files for inspection.

To check first-use confirmation, set `SSH_HOME` to a disposable directory with the fixture host key only in `known_hosts` at the root. The server must allow public-key authentication with the disposable identity. Run this command from the foreground terminal, substituting the fixture values:

```sh
ssh -p PORT -i /path/to/fixture-identity USER@HOST 'echo STOCK_SSH_CONFIRM_FIXTURE_OK'
```

Compare the displayed fingerprint with the fixture server's public key before replying `yes` or entering the exact fingerprint. The test command must succeed, `.ssh/known_hosts` must contain the verified key, and a second login must not prompt. The root file must remain unchanged. A wrong key in `.ssh/known_hosts` must still be refused. In fresh cases, test `no`, `BatchMode=yes`, `StrictHostKeyChecking=yes`, and an answer provided on redirected stdin; none should add a key. Redirecting stdout does not disable confirmation. If stderr is redirected, the prompt goes to that destination, while the answer still comes from the terminal. See [the Simulator test](../tests/README.md#stock-ssh-host-key-confirmation) for an automated loopback fixture.

`tests/stock-ssh-worker-tty.m` checks the worker broker's terminal flag without an extension pool. Link it against the Simulator ios_system framework with `-Wl,-export_dynamic` and place the matching SSHStock, SSHKeygenStock and OpenSSL frameworks on its runtime search path. Run it under `simctl spawn` with the app's `sshStockCommands.plist`, one mode per process and an optional client argument (`ssh` by default, or `ssh-keygen`). `foreground` and `stdout-file` must advertise a terminal; `pipe` and `stdin-file` must not.
