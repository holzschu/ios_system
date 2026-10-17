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
