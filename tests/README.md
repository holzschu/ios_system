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
