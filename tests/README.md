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
