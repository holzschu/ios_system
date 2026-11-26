#!/bin/bash
set -euo pipefail
export LC_ALL=C

if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <iphoneos|iphonesimulator> <arch> <Stock-binary> <verified-frameworks>" >&2
    exit 64
fi
sdk=$1; arch=$2; binary=$3; frameworks=$4
name=$(basename "$binary")
label="$name ($sdk/$arch)"
fail() { echo "$label: $*" >&2; exit 1; }
case "$sdk:$arch" in
    iphoneos:arm64) platform=IOS ;;
    iphonesimulator:arm64|iphonesimulator:x86_64) platform=IOSSIMULATOR ;;
    *) fail "unsupported SDK/architecture" ;;
esac
check_platform() {
    local file=$1 role=$2 build actual
    build=$(xcrun vtool -arch "$arch" -show-build "$file")
    actual=$(awk '$1 == "platform" {print $2}' <<< "$build")
    [ "$actual" = "$platform" ] || fail "$role: wrong Mach-O platform (${actual:-missing}; expected $platform)"
}
check_platform "$binary" 'Stock binary'
sdkroot=$(xcrun --sdk "$sdk" --show-sdk-path)
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# Keep library identity: another SDK dylib exporting the same name is not enough.
links=$(xcrun otool -arch "$arch" -L "$binary")
libs=$(awk '$2 == "(compatibility" {print $1}' <<< "$links")
while IFS= read -r lib; do
    case "$lib" in
        "@rpath/$name.framework/$name") continue ;;
        @rpath/ios_system.framework/ios_system|@rpath/openssl.framework/openssl)
            provider=${lib##*/}
            dependency="$frameworks/${lib#@rpath/}"
            check_platform "$dependency" "$lib"
            xcrun llvm-nm --arch="$arch" --add-dyldinfo -gUj "$dependency" > "$work/$provider" ;;
        /usr/lib/libSystem.B.dylib|/usr/lib/libresolv.9.dylib|/usr/lib/libz.1.dylib)
            provider=${lib##*/}; provider=${provider%%.*}
            stub="$sdkroot/${lib%.dylib}.tbd"
            stub_arch=$arch
            # Device SDKs may supply arm64e stubs for arm64 clients.
            if ! xcrun tapi archive --verify-arch "$stub_arch" "$stub"; then
                [ "$sdk" = iphoneos ] || fail "no matching SDK stub architecture: $lib"
                stub_arch=arm64e
                xcrun tapi archive --verify-arch "$stub_arch" "$stub" || fail "no matching SDK stub architecture: $lib"
            fi
            xcrun llvm-nm --arch="$stub_arch" --add-inlinedinfo -gUj "$stub" > "$work/$provider" ;;
        *) fail "unexpected dependency: $lib" ;;
    esac
    [ -s "$work/$provider" ] || fail "cannot read exports: $lib"
done <<< "$libs"

# The SDK can expose names App Store Connect still rejects. Check them in
# both directions: removing an import must not turn it into an export.
imports=$(xcrun llvm-nm --arch="$arch" --add-dyldinfo -um "$binary")
exports=$(xcrun llvm-nm --arch="$arch" --add-dyldinfo -gUj "$binary")
status=0
if grep -Fxq ___progname <<< "$exports"; then
    echo "$label: exports App Store-rejected symbol ___progname" >&2
    status=1
fi
awk -v work="$work" -v label="$label" '
    /\(undefined\)/ && $(NF-1) == "(from" && $NF ~ /\)$/ {
        provider = substr($NF, 1, length($NF) - 1)
        symbol = $(NF-2)
        if (symbol == "___progname") {
            print label ": imports App Store-rejected symbol " symbol " from " provider
            failed = 1
            next
        }
        if (provider ~ /^[[:alnum:]_]+$/) {
            if (!(provider in loaded)) {
                file = work "/" provider
                while ((getline line < file) > 0) exports[provider, line] = 1
                close(file)
                loaded[provider] = 1
            }
            if ((provider, symbol) in exports) next
        }
        print label ": no matching export for " symbol " from " provider
        failed = 1
        next
    }
    NF { print label ": unrecognized import: " $0; failed = 1 }
    END { exit failed }
' <<< "$imports" >&2 || status=1
[ "$status" -eq 0 ] || exit "$status"
printf '%s: imports match SDK stubs or verified framework exports; no ___progname\n' "$label"
