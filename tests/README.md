# Session window size

`window-size.m` calls the public session APIs against the real ios_system framework. It checks independent sessions, reading from a thread without session TLS, resize, closed and unknown sessions, invalid arguments and unchanged outputs on errors.

Build the framework and test executable, then run on an explicitly selected booted Simulator:

```sh
xcodebuild -project ios_system.xcodeproj -target ios_system -configuration Release -sdk iphonesimulator -jobs 2 ARCHS=arm64 CODE_SIGNING_ALLOWED=NO SYMROOT="$PWD/.build/window-size" OBJROOT="$PWD/.build/window-size-obj" build
mkdir -p .build/window-size-check/Frameworks
cp -R .build/window-size/Release-iphonesimulator/ios_system.framework .build/window-size-check/Frameworks/
xcrun --sdk iphonesimulator clang -target arm64-apple-ios14.0-simulator -isysroot "$(xcrun --sdk iphonesimulator --show-sdk-path)" -Wall -Wextra -Werror -I ios_system -F .build/window-size/Release-iphonesimulator -framework ios_system -framework Foundation -Wl,-rpath,@executable_path/Frameworks tests/window-size.m -o .build/window-size-check/window-size
xcrun simctl spawn "$SIMULATOR_UDID" "$PWD/.build/window-size-check/window-size"
```

Xcode 27 rejects deployment targets below iOS 15 in its build planner. For that SDK, pass `IPHONEOS_DEPLOYMENT_TARGET=15.0` to the local framework build and use `arm64-apple-ios15.0-simulator` for the test executable. This does not change the framework project's deployment settings. A run on a newer Simulator does not qualify runtime behavior on older iOS versions.

The caller must keep the queried session alive and coordinate session creation/closure with other users of the session APIs.

# Command signal handlers

`signal-handlers.m` loads a real command framework through `ios_system`. It checks that command-installed SIGINT, SIGUSR1 and SIGWINCH handlers are removed at command completion, the previous mask and flags are restored, and ignored or unrelated host dispositions survive. It uses synchronous command completion so assertions run after cleanup.

After building `ios_system.framework` as above, prepare the command fixture and executable (the paths below use the same framework build directory):

```sh
mkdir -p .build/signal-handlers/Frameworks/SignalHandler.framework
cp -R .build/window-size/Release-iphonesimulator/ios_system.framework .build/signal-handlers/Frameworks/
xcrun --sdk iphonesimulator clang -target arm64-apple-ios16.0-simulator -Wall -Wextra -Werror -dynamiclib tests/signal-handler-command.c -install_name @rpath/SignalHandler.framework/SignalHandler -o .build/signal-handlers/Frameworks/SignalHandler.framework/SignalHandler
plutil -create xml1 .build/signal-handlers/commandDictionary.plist
plutil -insert signal-handler -json '["@rpath/SignalHandler.framework/SignalHandler","signal_handler_main","","none"]' .build/signal-handlers/commandDictionary.plist
xcrun --sdk iphonesimulator clang -target arm64-apple-ios16.0-simulator -fobjc-arc -Wall -Wextra -Werror -I ios_system -F .build/signal-handlers/Frameworks -framework ios_system -framework Foundation -Wl,-rpath,@executable_path/Frameworks tests/signal-handlers.m -o .build/signal-handlers/signal-handlers
xcrun simctl spawn "$SIMULATOR_UDID" "$PWD/.build/signal-handlers/signal-handlers"
```

A successful run exits 0 and prints `PASS: command handlers restored; masks, flags, unrelated handlers and shared-command signals preserved`. The unpatched framework fails the first SIGINT restoration assertion.

The same executable starts two commands from one framework through separate public sessions. Both commands save their dispositions before installing SIGINT/SIGWINCH handlers; after one command finishes, SIGWINCH and `ios_kill` must still reach the survivor, and the last cleanup must restore the host handlers. Run the staggered variant too, where the second command starts after the first installs its handlers:

```sh
xcrun simctl spawn "$SIMULATOR_UDID" "$PWD/.build/signal-handlers/signal-handlers" --staggered
```

The staggered run exits 0 and prints `PASS: staggered shared commands preserve signals and restore host handlers`. Before shared-image lifetime tracking, both variants fail. On Xcode 27.1 the framework build additionally used `OTHER_CFLAGS='$(inherited) -Wno-int-conversion'` for existing source diagnostics; no production build setting was changed. Signal dispositions remain process-wide; callers must still coordinate concurrent changes to the same signal by different images.

# Detached command cwd restoration

`cwd-order.m` starts a detached command that changes directory, waits through the public `ios_waitpid` API, then runs a relative write. The file must appear in the shell's original directory. The test delays only `NSFileManager` directory restoration to expose premature completion, retaining its real side effects.

Build the framework as above, then compile and run this regression on an owned Simulator. Use a fresh result directory each time:

```sh
mkdir -p .build/cwd-check/Frameworks .build/cwd-check/result
cp -R .build/window-size/Release-iphonesimulator/ios_system.framework .build/cwd-check/Frameworks/
cp Resources/commandDictionary.plist .build/cwd-check/
xcrun --sdk iphonesimulator clang -target arm64-apple-ios15.0-simulator -isysroot "$(xcrun --sdk iphonesimulator --show-sdk-path)" -fobjc-arc -Wall -Wextra -Wno-unused-parameter -I ios_system -F .build/cwd-check/Frameworks -framework ios_system -framework Foundation -Wl,-rpath,@executable_path/Frameworks -Wl,-export_dynamic tests/cwd-order.m -o .build/cwd-check/cwd-order
xcrun simctl spawn "$SIMULATOR_UDID" "$PWD/.build/cwd-check/cwd-order" "$PWD/.build/cwd-check/result"
```

Expected: exit 0 and `relative write: shell=1 command=0 PASS`. Without the restoration-order fix: exit 1 and `relative write: shell=0 command=1 FAIL`. The ten-second alarm bounds a stalled command wait. This Simulator test does not qualify physical-device behavior.
# Reselecting session streams

`session-streams.m` creates two sessions, installs caller streams in the first, selects the second and reselects the first. It checks the public input descriptor and runs a registered command whose exact `SESSION\n` output must reach the original caller stream. It clears the caller thread's TLS streams before dispatch so the selected session supplies them.

Use the framework build and test compiler command above, replacing the source and executable name with `session-streams.m` and `session-streams`, adding `-fobjc-arc -Wl,-export_dynamic`, and copying `Resources/commandDictionary.plist` next to the executable. Success prints `bytes=8 PASS`; the broken session reselection resets stdin to fd 0 and leaves the capture empty. Session-list initialization must finish before concurrent use, and callers must keep sessions alive while commands or window-size readers use them.
# Native terminal detection

`native-tty.m` uses a real socket pair and the public session/stream APIs. The same executable resolves `ios_useNativeTTY` with `dlsym`, so it also runs against an unmodified framework. It verifies the default virtual terminal, actual socket descriptor state after opting in, and restoration of the default after opting out.

Build and run on an explicitly selected booted Simulator:

```sh
xcodebuild -project ios_system.xcodeproj -scheme ios_system -configuration Release -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/native-tty -jobs 2 ARCHS=arm64 CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=15.0 build
mkdir -p .build/native-tty-check/Frameworks
cp -R .build/native-tty/Build/Products/Release-iphonesimulator/ios_system.framework .build/native-tty-check/Frameworks/
xcrun --sdk iphonesimulator clang -target arm64-apple-ios15.0-simulator -isysroot "$(xcrun --sdk iphonesimulator --show-sdk-path)" -fobjc-arc -Wall -Wextra -Wno-unused-parameter -I ios_system -F .build/native-tty-check/Frameworks -framework ios_system -framework Foundation -Wl,-rpath,@executable_path/Frameworks tests/native-tty.m -o .build/native-tty-check/native-tty
xcrun simctl spawn "$SIMULATOR_UDID" "$PWD/.build/native-tty-check/native-tty"
```

The baseline exits 1 with `native=1/1/1 descriptor=1`. The patched framework exits 0 with `default=1 native=0/0/0 descriptor=0 restored=1 PASS`. This socket test does not qualify physical-device behavior or PTY support.
# Caller-owned streams

`owned-streams.m` exercises `ios_system`, a registered shell command and the additive stream registration API. The same executable runs against an unmodified framework by resolving the new functions with `dlsym`: without registration, command cleanup closes all three caller streams and the test exits 1. With registration, it checks that all descriptors remain open, appends output, reads the exact combined bytes and closes the streams itself. It substitutes no ios_system implementation.

From the repository root, build and run on an explicitly selected booted Simulator:

```sh
xcodebuild -project ios_system.xcodeproj -scheme ios_system -configuration Release -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' -derivedDataPath .build/owned-streams -jobs 2 ARCHS=arm64 CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=15.0 build
mkdir -p .build/owned-streams-check/Frameworks
cp -R .build/owned-streams/Build/Products/Release-iphonesimulator/ios_system.framework .build/owned-streams-check/Frameworks/
cp Resources/commandDictionary.plist .build/owned-streams-check/
xcrun --sdk iphonesimulator clang -target arm64-apple-ios15.0-simulator -isysroot "$(xcrun --sdk iphonesimulator --show-sdk-path)" -fobjc-arc -Wall -Wextra -Wno-unused-parameter -I ios_system -F .build/owned-streams-check/Frameworks -framework ios_system -framework Foundation -Wl,-rpath,@executable_path/Frameworks -Wl,-export_dynamic tests/owned-streams.m -o .build/owned-streams-check/owned-streams
xcrun simctl spawn "$SIMULATOR_UDID" "$PWD/.build/owned-streams-check/owned-streams"
```

The command dictionary must be next to the executable because command registration uses the main bundle's stock resource. The regression prints `caller streams still open: 3/3 PASS` and `caller stream read/write/close: PASS` on success. This test covers caller-owned FILE lifetime; interactive input leases and command-tree cancellation require separate tests.

# Owned command cancellation

`owned-cancellation.m` starts a registered native parent, whose child redirects all three streams, then cancels the registration through `ashell_cancel_owned_streams`. It waits through cleanup, unregisters, registers the same caller streams again and checks the next command's exact output. The registration follows descendants even when none of their streams match the original FILEs. Cancellation is sticky until unregistering; commands must reach pthread cancellation points. Stop dispatch before waiting or unregistering, and serialize those operations with cancellation.

Use the framework build and test compiler command above, replacing `owned-streams.m` and the executable name with `owned-cancellation.m` and `owned-cancellation`. Keep the command dictionary beside the executable. Pass an existing disposable directory for the child's redirected files:

```sh
mkdir -p .build/owned-cancellation-check/run
xcrun simctl spawn "$SIMULATOR_UDID" "$PWD/.build/owned-cancellation-check/owned-cancellation" "$PWD/.build/owned-cancellation-check/run"
```

Against the caller-owned-stream baseline without cancellation, the same executable exits 124 after five seconds. With cancellation it exits 0 and prints `redirected child cancelled; next command exact output: PASS`. This test does not qualify physical-device behavior or cancellation of native code without cancellation points.

# Foreground command input

`input-lease.m` lends a pipe to a native command while keeping a separate command-tree registration. It sends `INPUT\n` and EOF, waits through cleanup, closes the input itself and checks that a subsequent command produces the exact combined `INPUT\nNEXT\n`. The same executable resolves `ashell_register_command_input` with `dlsym` and runs against the cancellation prerequisite without that API.

Use the caller-owned-stream framework build and test compiler commands above, replacing the test source and executable name with `input-lease.m` and `input-lease`. Keep the command dictionary next to the executable. The baseline exits 1 with `ABI=0 kept=0 bytes=11`: output completes but cleanup has closed the caller's input. The lease registration must keep that input open until the caller unregisters and closes it. Stop dispatch and wait for completion before unregistering; the input lease does not replace the command tree's cancellation registration. Hosts that call from an existing thread must install the intended session streams and command-thread TLS before each command.

Run the input fixture a second time with argument `cancel`. It keeps the pipe writer open, cancels through the original tree registration and expects only `NEXT\n` after cleanup. The fixture uses a cancellable `read` syscall; blocked stdio reads are not guaranteed to unwind on pthread cancellation. This variant catches a stdin-only registration incorrectly replacing the tree cancellation owner.
# Wasm stdin descriptor

`wasm-stdin-close.m` registers a stand-in producer `emit` and a consumer named `wasm` (the name `cleanup_function` special-cases), runs `emit | wasm` fifty times through `ios_system`, and compares the process's open descriptors before and after. Without the fix each pipeline leaves the read end of its pipe open.

Build the framework as above, then:

```sh
mkdir -p .build/wasm-stdin-check/Frameworks
cp -R .build/window-size/Release-iphonesimulator/ios_system.framework .build/wasm-stdin-check/Frameworks/
cp Resources/commandDictionary.plist .build/wasm-stdin-check/
xcrun --sdk iphonesimulator clang -target arm64-apple-ios15.0-simulator -isysroot "$(xcrun --sdk iphonesimulator --show-sdk-path)" -fobjc-arc -Wall -Wextra -Wno-unused-parameter -I ios_system -F .build/wasm-stdin-check/Frameworks -framework ios_system -framework Foundation -Wl,-rpath,@executable_path/Frameworks -Wl,-export_dynamic tests/wasm-stdin-close.m -o .build/wasm-stdin-check/wasm-stdin-close
xcrun simctl spawn "$SIMULATOR_UDID" "$PWD/.build/wasm-stdin-check/wasm-stdin-close"
```

Expected: exit 0 and `descriptors after 50 pipelines: before=N after=N PASS`. Without the fix the count grows by about one per pipeline and the test exits 1. This Simulator test does not qualify physical-device behavior.

# Wasm command position

`wasm-command-order.m` starts a detached command through `ios_system`, pauses its external WASM-engine fixture after preparation, and lets `ios_full_waitpid(..., WNOHANG)` drain the host queue. The command must still read its reserved position through `webAssemblyCommandOrder` after the drain resets the next queue's counter.

After building the framework as above:

```sh
mkdir -p .build/wasm-order-check/Frameworks
cp -R .build/window-size/Release-iphonesimulator/ios_system.framework .build/wasm-order-check/Frameworks/
cp Resources/commandDictionary.plist .build/wasm-order-check/
xcrun --sdk iphonesimulator clang -target arm64-apple-ios16.0-simulator -isysroot "$(xcrun --sdk iphonesimulator --show-sdk-path)" -Wall -Wextra -Wno-unused-parameter -I ios_system -F .build/wasm-order-check/Frameworks -framework ios_system -framework Foundation -Wl,-rpath,@executable_path/Frameworks tests/wasm-command-order.m -o .build/wasm-order-check/wasm-command-order
xcrun simctl spawn "$SIMULATOR_UDID" "$PWD/.build/wasm-order-check/wasm-command-order"
```

Expected: exit 0 and `WASM command order after host drain: expected=1 actual=1`. Without the fix the command reads 0 and the test exits 1. A five-second alarm bounds a stalled wait. The fixture replaces the external WASM engine; command dispatch and waits use the real framework.
# Waiting for a command

`waitpid-idle.m` starts a 1.5 s command behind `ios_fork`, calls `ios_waitpid` and compares the process CPU time with the wall time of the wait. The wait must sleep: CPU time stays under a quarter of wall time. A polling wait burns about one core for the whole second and a half.

Build the framework as above, then compile and run it on an owned Simulator:

```sh
mkdir -p .build/waitpid-check/Frameworks
cp -R .build/window-size/Release-iphonesimulator/ios_system.framework .build/waitpid-check/Frameworks/
cp Resources/commandDictionary.plist .build/waitpid-check/
xcrun --sdk iphonesimulator clang -target arm64-apple-ios15.0-simulator -isysroot "$(xcrun --sdk iphonesimulator --show-sdk-path)" -fobjc-arc -Wall -Wextra -Wno-unused-parameter -I ios_system -F .build/waitpid-check/Frameworks -framework ios_system -framework Foundation -Wl,-rpath,@executable_path/Frameworks -Wl,-export_dynamic tests/waitpid-idle.m -o .build/waitpid-check/waitpid-idle
xcrun simctl spawn "$SIMULATOR_UDID" "$PWD/.build/waitpid-check/waitpid-idle"
```

Expected: exit 0 and `ios_waitpid: wall=1.5s cpu=0.0s PASS`. With the polling wait: exit 1 and `FAIL`. The twenty-second alarm bounds a stalled wait.

# Command thread creation failure

`thread-create-failure.m` dispatches a registered native command through `ios_system`. The external `thread-create-failure-hook.c` interposer makes exactly one OS `pthread_create` call return `EAGAIN`; the framework itself is not instrumented. With allocator scribbling enabled, cleanup must return status 126, preserve all three caller-owned streams and the caller's `SIGUSR1` handler, then run the next command with exact `NEXT\n` output. A ten-second alarm bounds a stalled wait.

After building the framework as above:

```sh
mkdir -p .build/thread-create-check/Frameworks
cp -R .build/owned-streams/Build/Products/Release-iphonesimulator/ios_system.framework .build/thread-create-check/Frameworks/
cp Resources/commandDictionary.plist .build/thread-create-check/
xcrun --sdk iphonesimulator clang -target arm64-apple-ios16.0-simulator -isysroot "$(xcrun --sdk iphonesimulator --show-sdk-path)" -fobjc-arc -Wall -Wextra -Wno-unused-parameter -I ios_system -F .build/thread-create-check/Frameworks -framework ios_system -framework Foundation -Wl,-rpath,@executable_path/Frameworks -Wl,-export_dynamic tests/thread-create-failure.m -o .build/thread-create-check/thread-create-failure
xcrun --sdk iphonesimulator clang -target arm64-apple-ios16.0-simulator -isysroot "$(xcrun --sdk iphonesimulator --show-sdk-path)" -Wall -Wextra -dynamiclib tests/thread-create-failure-hook.c -o .build/thread-create-check/thread-create-failure-hook.dylib
SIMCTL_CHILD_DYLD_INSERT_LIBRARIES="$PWD/.build/thread-create-check/thread-create-failure-hook.dylib" SIMCTL_CHILD_MallocScribble=1 SIMCTL_CHILD_MallocPreScribble=1 xcrun simctl spawn "$SIMULATOR_UDID" "$PWD/.build/thread-create-check/thread-create-failure"
```

Expected: exit 0 and `thread creation failure: status=126; streams, signal and next output: PASS`. Set both `MallocScribble` and `MallocPreScribble`.

# Per-child exit status

`child-wait-status.m` starts two registered commands through `ios_fork` and `ios_system`. The first returns 7. The second waits for the first through `ios_waitpid`, then calls `ios_exit(23)`. The parent waits for the second and then the first through `ios_full_waitpid`; each wait must report that child's exit status. It also checks a missing command returns 127 and empty and NULL commands return 0.

From the repository root, build and run on an explicitly selected booted Simulator:

```sh
xcodebuild -project ios_system.xcodeproj -target ios_system -configuration Release -sdk iphonesimulator -jobs 2 ARCHS=arm64 CODE_SIGNING_ALLOWED=NO IPHONEOS_DEPLOYMENT_TARGET=15.0 CONFIGURATION_BUILD_DIR="$PWD/.build/child-status-sdk" OBJROOT="$PWD/.build/child-status-obj" build
mkdir -p .build/child-status/Frameworks
cp -R .build/child-status-sdk/ios_system.framework .build/child-status/Frameworks/
cp Resources/commandDictionary.plist .build/child-status/
xcrun --sdk iphonesimulator clang -target arm64-apple-ios15.0-simulator -isysroot "$(xcrun --sdk iphonesimulator --show-sdk-path)" -fobjc-arc -Wall -Wextra -Wno-unused-parameter -I ios_system -F .build/child-status/Frameworks -framework ios_system -framework Foundation -Wl,-rpath,@executable_path/Frameworks -Wl,-export_dynamic tests/child-wait-status.m -o .build/child-status/child-status
codesign --force --sign - .build/child-status/Frameworks/ios_system.framework
codesign --force --sign - .build/child-status/child-status
xcrun simctl spawn "$SIMULATOR_UDID" "$PWD/.build/child-status/child-status"
```

Expected: exit 0 and `child A expected=7 observed=7; child B expected=23 observed=23: PASS`, `missing command expected=127 observed=127` and `empty command expected=0 observed=0; NULL command expected=0 observed=0`. With shared session status, both children report 23 and the test exits 1. A ten-second alarm bounds a stalled wait. This fixture covers a normal return, `ios_exit` and commands that do not start; it does not qualify cancellation, thread-creation failure or PID reuse.

# Worker registry selection

`worker-registry-selection.sh` checks the public shell route in a disposable worker-enabled host. Put a `git` script that prints `DISPATCH_WRAPPER_SELECTED` first in the host's PATH, then run the test with the absolute zero-byte native Git marker as its argument. The bare command must select the wrapper; the absolute marker must print `git version ...`. The wrapper belongs only in a disposable test container. Set its HOME and working directory to that container before launching the test. Expected: exit 0 and `WORKER_REGISTRY_SELECTION_PASS`. Without preserving the resolved registry selection across worker dispatch, the absolute marker selects the wrapper again and the test exits 1.

# Spawned worker resource usage

`spawn-rusage.m` exercises the public `ios_posix_spawn`, `ios_wait4` and `ios_killpid` APIs against real isolated workers. Its CPU-bound awk child must return a successful wait status, available usage and positive user time; its killed sleep child must return exit 137 with unavailable usage. The snapshot is worker `RUSAGE_SELF`, including process startup, rather than command-only CPU time.

Build this fixture as a command framework with `-Dmain=spawn_rusage_main`, linking Foundation and the matching ios_system framework. In a disposable worker-enabled host, register `spawn-rusage` as `["SpawnRusageChecks.framework/SpawnRusageChecks", "spawn_rusage_main", "", "file"]` and provide its empty app/bin marker. Invoke the absolute marker with the test container HOME as its only argument, after setting HOME and cwd to that container. The host and every worker need the matching resource-usage broker protocol; a plain standalone Simulator process has no worker broker. No production test entry point is required.

The arm64 Simulator host with five workers on Xcode 27.1 exited 0 with `CPU child user time: 0.517716` and `spawn-rusage: CPU measured, killed child unavailable PASS`. The baseline fails compilation because it has no public `ios_wait4`. This does not qualify physical-device behavior.

# Detached spawned worker context

`spawn-context.m` uses `ios_posix_spawn`, `ios_wait4` and `ios_killpid` in a disposable worker-enabled host. It changes the parent cwd while a child sleeps, then verifies completion preserves the parent cwd. A second child receives SIGTERM; wait must return exit 143 while the parent command status stays unchanged.

Build/register it as a command framework with `-Dmain=spawn_context_main`, Foundation and the matching ios_system framework. Register `spawn-context` as `["SpawnContextChecks.framework/SpawnContextChecks", "spawn_context_main", "", "file"]`, provide its empty app/bin marker, and pass the disposable host HOME as its only argument. The baseline fails the cwd check; the fixed implementation must pass both checks.

# Spawned PID ownership

`spawn-pid-reuse.m` waits for a real worker, recycles its PID through the public allocator, registers an ordinary thread and sends SIGINT through `ios_killpid`. Expected: the signal handler runs; the ordinary thread is not cancelled. This fails when worker ownership is not reset on PID allocation. The ordinary thread explicitly unblocks SIGINT because the host may pass a blocked mask.

`spawn-registration.m` uses an external `pthread_create` scheduling interposer (`spawn-thread-start-hook.c`) to complete an older public PID immediately before a strict child thread starts. Expected: the returned child is registered, bounded WNOHANG polling returns that child and status 0. It also checks that the older PID completed, so an inactive interposer cannot produce a pass. A second run with argument `fail` makes that OS call return EAGAIN and verifies the reserved child slot is released. These guard registration and error cleanup against changes to the global current PID. The hook changes the OS scheduling boundary; ios_system is not instrumented.

Build/register these as PidReuseChecks.framework/pid_reuse_main and SpawnRegistrationChecks.framework/spawn_registration_main, with command markers pid-reuse and spawn-registration. Each takes the disposable host HOME. Build the hook as a Simulator dylib linked to the matching ios_system framework and insert it only for the registration test using SIMCTL_CHILD_DYLD_INSERT_LIBRARIES when launching the disposable host. Keep the interposer out of production builds. The cwd check in spawn-context also covers the cwd-free PID release.

`worker-nested-environment.m` registers a parent command (nested_environment_main) and payload (nested_environment_payload_main) in a disposable host; register the payload in workers too. The parent invokes ios_system without ios_fork, with the payload admitted by ASHELL_WORKER_COMMANDS and a custom environment value. Expected: the payload runs in another process, sees the value and exits 0. This guards environment lookup for an unforked command whose parameter PID is -1. No production entry point or internal mock is required.

`worker-pipeline-signal.m` checks a real worker producer piped into an ordinary command thread under one reserved PID. The external `pipeline-thread-start-hook.c` delays the first OS thread until both stages have captured that reservation, then lets the consumer register first. After the producer exits, SIGINT must reach the consumer's handler and let it return normally. The fixture asserts the producer used another process. A stale worker flag cancels the consumer instead. Register `pipeline-signal`, `pipeline-signal-producer` and `pipeline-signal-consumer` from PipelineSignalChecks.framework, exporting `pipeline_signal_main` (compile with `-Dmain=pipeline_signal_main`), `pipeline_signal_producer` and `pipeline_signal_consumer`. Register the producer in the worker bundles too. The hook controls OS scheduling only and is excluded from production builds.

For both scheduling hooks, compile against the matching Simulator framework and launch only the disposable host with the hook inserted:

```sh
xcrun --sdk iphonesimulator clang -target arm64-apple-ios26.0-simulator -dynamiclib -fblocks -F "$FRAMEWORK_DIR" -framework ios_system tests/spawn-thread-start-hook.c -o "$FIXTURE_APP/Frameworks/SpawnThreadHook.dylib"
codesign --force --sign - "$FIXTURE_APP/Frameworks/SpawnThreadHook.dylib"
codesign --force --sign - --preserve-metadata=entitlements "$FIXTURE_APP"
SIMCTL_CHILD_DYLD_INSERT_LIBRARIES="$INSTALLED_APP/Frameworks/SpawnThreadHook.dylib" xcrun simctl launch "$SIMULATOR_UDID" "$FIXTURE_BUNDLE_ID"
```

Use the host's command entry point to run `spawn-registration <disposable-home>` and `spawn-registration <disposable-home> fail`. For the pipeline check compile `pipeline-thread-start-hook.c` the same way into its own `PipelineThreadHook.dylib`, insert that dylib instead of `SpawnThreadHook.dylib`, and run `pipeline-signal`. Resolve `INSTALLED_APP` with `simctl get_app_container` after installation; the source build directory is not the installed path. A passing registration run reports `completed=1 registered=1` and status 0. The injected failure reports EAGAIN with `child=-1 released=1`. A passing pipeline reports `signal=1 returned=1 isolated=1 ordered=1`. The ordering assertion prevents a pass when the OS hook does not match.
