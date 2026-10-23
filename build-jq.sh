#!/bin/bash
# Build official jq as an ios_system native command framework.
set -euo pipefail
root=$(cd "$(dirname "$0")" && pwd -P)
case "$root" in
  *' '*) echo 'build-jq.sh: checkout path must not contain spaces' >&2; exit 1;;
esac
work="$root/.build/jq"
version=1.8.2
jobs=${JOBS:-4}
mkdir -p "$work/downloads" "$work/source" "$work/output"

fetch() {
  local name=$1 sha=$2 url=$3
  if [ ! -f "$work/downloads/$name" ]; then
    curl --fail --location --retry 3 "$url" -o "$work/downloads/$name.part"
    echo "$sha  $work/downloads/$name.part" | shasum -a 256 -c -
    mv "$work/downloads/$name.part" "$work/downloads/$name"
  fi
  echo "$sha  $work/downloads/$name" | shasum -a 256 -c -
}

fetch jq.tar.gz 71b8d6e8f5fe81f6c6d0d110e3892251f6ce76ed095abd315e26e6e1193af3af \
  "https://github.com/jqlang/jq/releases/download/jq-$version/jq-$version.tar.gz"
fetch ios_system.zip d429e68102926f58bedd8e8b7105dcd169478cd6da1cef494a5f468482d1c8f5 \
  https://github.com/holzschu/ios_system/releases/download/v3.0.5/ios_system.xcframework.zip
if [ ! -f "$work/source/configure" ]; then
  tar -xzf "$work/downloads/jq.tar.gz" --strip-components=1 -C "$work/source"
fi
if ! patch -s -f -F 0 --dry-run -R -p1 -d "$work/source" < "$root/jq/streams.patch" >/dev/null 2>&1; then
  patch -s -f -F 0 -p1 -d "$work/source" < "$root/jq/streams.patch"
fi
[ -d "$work/ios_system.xcframework" ] || unzip -q "$work/downloads/ios_system.zip" -d "$work"

build_slice() {
  local sdk=$1 arch=$2 dependency=$3 platform=$4
  local triple="$arch-apple-ios14.0" host="$arch-apple-darwin"
  local build="$work/build-$sdk-$arch" framework="$work/$sdk-$arch/jq.framework"
  local sysroot cc
  [ "$sdk" != iphonesimulator ] || triple="$triple-simulator"
  [ "$arch" != arm64 ] || host=aarch64-apple-darwin
  sysroot=$(xcrun --sdk "$sdk" --show-sdk-path)
  cc=$(xcrun --sdk "$sdk" -f clang)
  mkdir -p "$build" "$framework"
  (
    cd "$build"
    CC="$cc -target $triple -isysroot $sysroot" \
      CFLAGS="-O2 -fPIC -include $root/jq/ios-stdio.h" \
      LDFLAGS="-F$work/ios_system.xcframework/$dependency -framework ios_system" \
      "$work/source/configure" --build="$("$work/source/config/config.guess")" --host="$host" \
      --disable-shared --enable-static --disable-docs --disable-maintainer-mode --with-oniguruma=builtin
    make -j"$jobs"
  ) > "$work/$sdk-$arch.log" 2>&1 || {
    tail -n 40 "$work/$sdk-$arch.log" >&2
    return 1
  }
  "$cc" -target "$triple" -isysroot "$sysroot" -dynamiclib \
    "$build/src/main.o" "$build/.libs/libjq.a" "$build/vendor/oniguruma/src/.libs/libonig.a" \
    -F"$work/ios_system.xcframework/$dependency" -framework ios_system \
    -install_name @rpath/jq.framework/jq -o "$framework/jq"
  cat > "$framework/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>jq</string>
<key>CFBundleIdentifier</key><string>org.jqlang.jq</string>
<key>CFBundleName</key><string>jq</string>
<key>CFBundlePackageType</key><string>FMWK</string>
<key>CFBundleShortVersionString</key><string>$version</string>
<key>CFBundleVersion</key><string>1</string>
<key>MinimumOSVersion</key><string>14.0</string>
<key>CFBundleSupportedPlatforms</key><array><string>$platform</string></array>
</dict></plist>
EOF
  test "$(lipo -archs "$framework/jq")" = "$arch"
  nm -gU "$framework/jq" | grep ' T _main$' >/dev/null
  cp "$work/source/COPYING" "$framework/LICENSE.jq"
  cp "$work/source/vendor/oniguruma/COPYING" "$framework/LICENSE.oniguruma"
}

build_slice iphoneos arm64 ios-arm64 iPhoneOS
build_slice iphonesimulator arm64 ios-arm64_x86_64-simulator iPhoneSimulator
build_slice iphonesimulator x86_64 ios-arm64_x86_64-simulator iPhoneSimulator
simulator="$work/iphonesimulator/jq.framework"
mkdir -p "$simulator"
cp "$work/iphonesimulator-arm64/jq.framework/Info.plist" "$simulator/Info.plist"
cp "$work/iphonesimulator-arm64/jq.framework/"LICENSE.* "$simulator/"
lipo -create "$work/iphonesimulator-arm64/jq.framework/jq" "$work/iphonesimulator-x86_64/jq.framework/jq" -output "$simulator/jq"
codesign --force --sign - "$work/iphoneos-arm64/jq.framework"
codesign --force --sign - "$simulator"
rm -rf "$work/output/jq.xcframework"
xcodebuild -create-xcframework -framework "$work/iphoneos-arm64/jq.framework" \
  -framework "$simulator" -output "$work/output/jq.xcframework"
while IFS= read -r binary; do
  file "$binary"
  xcrun vtool -show-build "$binary"
  otool -L "$binary"
  if otool -L "$binary" | grep $'^\t' | grep -E '/opt/homebrew|/usr/local|/Users/runner'; then exit 1; fi
done < <(printf '%s\n' "$work/output/jq.xcframework"/*/jq.framework/jq)
(
  cd "$work/output"
  rm -f jq.xcframework.zip
  ditto -c -k --sequesterRsrc --keepParent jq.xcframework jq.xcframework.zip
  swift package compute-checksum jq.xcframework.zip | awk '{print $1 "  jq.xcframework.zip"}' > checksums.txt
  cat > release.md <<EOF
jq $version built from the official release tarball (SHA256 71b8d6e8f5fe81f6c6d0d110e3892251f6ce76ed095abd315e26e6e1193af3af), with its bundled Oniguruma 6.9.10.

Device: arm64 iOS14.0. Simulator: arm64 and x86_64 iOS14.0. Entry point: main. Requires the host app's ios_system framework (build dependency pinned to v3.0.5). The adapter uses ios_system command-thread streams and exit; stdout is flushed instead of closed.

Update the jq binaryTarget URL to this release's jq.xcframework.zip and copy its checksum from checksums.txt. Existing release assets are never replaced.
EOF
  cat checksums.txt
)
