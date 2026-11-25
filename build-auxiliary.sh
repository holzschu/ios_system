#!/bin/bash
set -euo pipefail

root=$(cd "$(dirname "$0")" && pwd)
build="$root/.build/auxiliary"
inputs="$build/inputs"
mkdir -p "$inputs"
fetch() {
    local url=$1 expected=$2 file=$3
    if [[ ! -f $file ]] || [[ $(shasum -a 256 "$file" | awk '{print $1}') != "$expected" ]]; then
        curl --fail --location --retry 3 "$url" -o "$file"
    fi
    printf '%s  %s\n' "$expected" "$file" | shasum -a 256 -c -
}
fetch https://github.com/holzschu/ios_system/releases/download/v3.0.5/ios_system.xcframework.zip d429e68102926f58bedd8e8b7105dcd169478cd6da1cef494a5f468482d1c8f5 "$inputs/ios_system.zip"
fetch https://github.com/holzschu/ios_system/releases/download/v3.0.5/ios_error.h 51d46b912eb30399cbb5c36c8c8f15eb1a44adcfc9ee581304ac9d3739a84716 "$inputs/ios_error.h"
fetch https://www.crufty.net/ftp/pub/sjg/old/bmake-20200606.tar.gz 67a3a27b3156e7d07dd5cd3501c64c69d50ed6752a59e616f50820f3d10b7002 "$inputs/bmake.tar.gz"
fetch https://github.com/pmachapman/unrar/archive/7dbf7ec906c304bbadae0aa783ffd6dd6b3e373b.tar.gz 72e3bc1c69177bc548c5e62680452954d30903d3de811ed96dda4cb9a7faeaa2 "$inputs/unrar.tar.gz"
fetch https://github.com/holzschu/ios_system/releases/download/Auxiliary/make.xcframework.zip 6f9dca82bfdee1be8ad0ec1e52870bee6b3e309ac29f0995a6d5a41003c26d4f "$inputs/published-make.zip"
fetch https://github.com/holzschu/ios_system/releases/download/Auxiliary/unrar.xcframework.zip b1c2318db3b89a668abd66f69036ec9c3c5d474b2d75a0b1ffbaf2ac47b02782 "$inputs/published-unrar.zip"
fetch https://mandoc.bsd.lv/snapshots/mandoc-1.14.5.tar.gz 8219b42cb56fc07b2aa660574e6211ac38eefdbf21f41b698d3348793ba5d8f7 "$inputs/mandoc.tar.gz"
fetch https://github.com/holzschu/ios_system/releases/download/Auxiliary/mandoc.xcframework.zip 86428238cb357ece2da6b813fe493dfcee1f4efc91ec535d73b3e581d9b8e21b "$inputs/published-mandoc.zip"
rm -rf "$inputs/ios_system.xcframework" "$inputs/published"
unzip -q "$inputs/ios_system.zip" -d "$inputs"
for product in make mandoc unrar; do
    mkdir -p "$inputs/published/$product"
    unzip -q "$inputs/published-$product.zip" -d "$inputs/published/$product"
    baseline="$inputs/published/$product/$product.xcframework/ios-arm64/$product.framework/$product"
    xcrun nm -arch arm64 -gjU "$baseline" | LC_ALL=C sort -u > "$build/$product.expected-arm64.txt"
    for target in arm64-apple-ios14.0 arm64-apple-ios14.0-simulator x86_64-apple-ios14.0-simulator; do
        arch=${target%%-*}
        sdk=iphonesimulator
        slice=ios-arm64_x86_64-simulator
        platform=iPhoneSimulator
        if [[ $target == arm64-apple-ios14.0 ]]; then
            sdk=iphoneos; slice=ios-arm64; platform=iPhoneOS
        fi
        work="$build/$product/$target"
        rm -rf "$work"
        mkdir -p "$work/source" "$work/objects" "$work/$product.framework"
        framework="$work/$product.framework"
        sysroot=$(xcrun --sdk "$sdk" --show-sdk-path)
        link="-dynamiclib -Wl,-install_name,@rpath/$product.framework/$product -F $inputs/ios_system.xcframework/$slice -framework ios_system"
        if [[ $product == make ]]; then
            tar -xzf "$inputs/bmake.tar.gz" -C "$work/source" --strip-components=1
            # Reconstructed from the published framework's disassembly, not recovered port source.
            # Unlike the historical local environ assignment, storeEnvironment updates the host.
            patch -d "$work/source" -p1 < "$root/ci/auxiliary/bmake-ios.patch"
            (
                cd "$work/objects"
                CC="$(xcrun --sdk "$sdk" --find clang) -target $target -isysroot $sysroot" CFLAGS='-Oz -fPIC -D_DARWIN_C_SOURCE=1' \
                    sh "$work/source/configure" --host="$arch-apple-ios" --with-machine="$arch" --with-machine_arch="$arch" --without-filemon
                # Keep configure's target link probes executable-shaped; only bootstrap links a framework.
                sed -i '' "s|^CFLAGS=\"|CFLAGS=\"-I $inputs -include $root/ci/auxiliary/bmake-ios.h |" make-bootstrap.sh
                sed -i '' "s|^LDFLAGS=\"|LDFLAGS=\"$link |" make-bootstrap.sh
                sh make-bootstrap.sh
            )
            cp "$work/objects/bmake" "$framework/make"
        elif [[ $product == mandoc ]]; then
            tar -xzf "$inputs/mandoc.tar.gz" -C "$work/source" --strip-components=1
            patch -d "$work/source" -p1 < "$root/ci/auxiliary/mandoc-configure.patch"
            patch -d "$work/source" -p1 < "$root/ci/auxiliary/mandoc-ios.patch"
            cp "$root/ci/auxiliary/mandoc.configure.local" "$work/source/configure.local"
            compiler=("$(xcrun --sdk "$sdk" --find clang)" -target "$target" -isysroot "$sysroot")
            printf "CC='%s'\nCFLAGS='-Oz -D_DARWIN_C_SOURCE=1'\n" "${compiler[*]}" >> "$work/source/configure.local"
            (
                cd "$work/source"
                # No target probe is executed; explicit choices must pass the target compiler/linker.
                sh configure
                for feature in dirent-namlen be32toh EFTYPE err getline getsubopt isblank mkdtemp ntohl O_DIRECTORY PATH_MAX progname rewb-bsd strcasestr stringlist strlcat strlcpy strndup strptime strsep strtonum vasprintf fts wchar nanosleep; do
                    "${compiler[@]}" -Oz -D_DARWIN_C_SOURCE=1 -DSYS_ENDIAN '-DUTF8_LOCALE="en_US.UTF-8"' \
                        -Werror=unguarded-availability-new "test-$feature.c" -o "test-$feature"
                done
                make -j4 mandoc CC="${compiler[*]}" CFLAGS="-Oz -fPIC -D_DARWIN_C_SOURCE=1 -I $inputs -include $root/ci/auxiliary/mandoc-ios.h" LDFLAGS="$link"
            )
            cp "$work/source/mandoc" "$framework/mandoc"
        else
            tar -xzf "$inputs/unrar.tar.gz" -C "$work/source" --strip-components=1
            printf '\n#include "%s/ci/auxiliary/unrar-ios.h"\n' "$root" >> "$work/source/rar.hpp"
            (
                cd "$work/source"
                # The unrar target depends on clean; omit that prerequisite from the parallel build.
                make -j4 -o clean unrar CXX="$(xcrun --sdk "$sdk" --find clang++) -target $target -isysroot $sysroot" \
                    CXXFLAGS="-Oz -fPIC -D_DARWIN_C_SOURCE=1 -I $inputs" LDFLAGS="$link" STRIP=: \
                    DEFINES='-D_FILE_OFFSET_BITS=64 -D_LARGEFILE_SOURCE'
            )
            cp "$work/source/unrar" "$framework/unrar"
        fi
        cat > "$framework/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>$product</string>
<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
<key>CFBundleIdentifier</key><string>Nicolas-Holzschuch.$product</string>
<key>CFBundleName</key><string>$product</string>
<key>CFBundlePackageType</key><string>FMWK</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleSupportedPlatforms</key><array><string>$platform</string></array>
<key>MinimumOSVersion</key><string>14.0</string>
<key>UIDeviceFamily</key><array><integer>1</integer><integer>2</integer></array>
</dict></plist>
PLIST
        expected="$build/$product.expected-arm64.txt"
        if [[ $product == unrar && $arch == x86_64 ]]; then
            baseline="$inputs/published/unrar/unrar.xcframework/ios-x86_64-simulator/unrar.framework/unrar"
            xcrun nm -arch x86_64 -gjU "$baseline" | LC_ALL=C sort -u > "$build/unrar.expected-x86_64.txt"
            expected="$build/unrar.expected-x86_64.txt"
        fi
        xcrun nm -arch "$arch" -gjU "$framework/$product" | LC_ALL=C sort -u > "$work/exports.txt"
        diff -u "$expected" "$work/exports.txt"
    done
    rm -rf "$build/$product/simulator" "$build/$product.xcframework"
    mkdir -p "$build/$product/simulator"
    cp -R "$build/$product/arm64-apple-ios14.0-simulator/$product.framework" "$build/$product/simulator/"
    xcrun lipo -create "$build/$product/arm64-apple-ios14.0-simulator/$product.framework/$product" \
        "$build/$product/x86_64-apple-ios14.0-simulator/$product.framework/$product" -output "$build/$product/simulator/$product.framework/$product"
    xcodebuild -create-xcframework -framework "$build/$product/arm64-apple-ios14.0/$product.framework" \
        -framework "$build/$product/simulator/$product.framework" -output "$build/$product.xcframework"
    rm -f "$build/$product.xcframework.zip"
    (cd "$build" && zip -rq "$product.xcframework.zip" "$product.xcframework")
done
: > "$build/checksums.txt"
for product in make mandoc unrar; do
    zip="$build/$product.xcframework.zip"
    sum=$(swift package compute-checksum "$zip")
    printf '%s  %s\n' "$sum" "${zip##*/}" >> "$build/checksums.txt"
    bash "$root/ci/auxiliary/audit-exports.sh" "$product" "$zip" "$inputs/published-$product.zip" "$inputs/ios_system.zip" > "$zip.exports.txt"
    uv run --script "$root/ci/audit-artifact.py" "$zip" --sha256 "$sum" --max-minos 14.0 > "$zip.audit.json"
done
