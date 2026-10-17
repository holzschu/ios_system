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
