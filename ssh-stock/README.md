# Stock OpenSSH clients

Builds on a-shell#1089 and holzschu/ios_system#201. The application worker foundation must provide nested isolated spawn with terminal selection and separate stderr. The qualified generic foundation includes that follow-up and explicit root identities.

This recipe builds OpenSSH 10.6p1 ssh, ssh-keygen, scp and sftp from the verified portable release archive. The adapter uses ios_system command streams and its isolated spawn API for child SSH commands. The application opts the stock client commands into `ASHELL_WORKER_COMMANDS`. Each opted-in invocation needs a fresh extension process; missing worker APIs or worker exhaustion return status 127 instead of running these programs in a shared thread. The application must set ASHELL_WORKER_ROOT_PID to its reserved ios_system PID before executing a worker root command.

After each remote-source SCP transfer, the adapter waits for the SSH child and checks its exit status before starting the next source. This uses the same wait/status handling as stock SCP's remote-to-remote SFTP path and keeps sequential transfers within one child-worker reservation.

Download https://cdn.openbsd.org/pub/OpenBSD/OpenSSH/portable/openssh-10.6p1.tar.gz into INPUTS, then run:

```sh
bash ssh-stock/build.sh iphonesimulator INPUTS FRESH_OUTPUT VERIFIED_FRAMEWORKS
```

Use iphoneos for device frameworks. VERIFIED_FRAMEWORKS contains matching ios_system.framework and openssl.framework inputs. The output contains four unsigned frameworks and source/toolchain/input receipts. Signing, embedding the frameworks and command registration belong to the application.

Strict POSIX spawn remains extension-only.

The recipe retains the supplied OpenSSL version. The tested input was OpenSSL 1.1.1w; updating that dependency is separate work.

With a disposable SSH host and identity, the public CLI check runs as:

```sh
dash ssh-stock/phone-client.sh ABSOLUTE_NEW_CASE_DIRECTORY HOST PORT USER IDENTITY KNOWN_HOSTS
```

The check covers Ed25519 generation/readback, strict key login and byte-identical scp/sftp transfers, including multiple remote SCP sources in one invocation, a missing source returning a nonzero status while a later source still transfers, and a successful login afterward. Phone qualification on 2026-10-23 passed the original transfer fixture with the production worker correction. The later multi-source SCP regression first exhausted a three-worker Simulator pool, then passed through the same SSH caller with the same three-worker capacity after the transport-wait correction. A preserved identity, SSH config and known_hosts created by the old 8.5 build also passed strict login. These results qualify the integrated worker build; these phone results do not qualify later public-source revisions.

Run `dash ssh-stock/home-migration.sh CASE_DIR HOST PORT USER THROWAWAY_IDENTITY KNOWN_HOSTS` through the app to verify default config, Ed25519 identity and strict known_hosts lookup using `SSH_HOME/.ssh`, without `-F`, `-i` or `UserKnownHostsFile`. The adapter uses the existing app `SSH_HOME` root (Documents by default), falling back to HOME when that override is absent. Keep CASE_DIR fresh; the fixture retains its throwaway files for inspection.
