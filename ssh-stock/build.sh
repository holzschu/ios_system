#!/bin/bash
set -euo pipefail
# Build stock OpenSSH client frameworks; the application owns signing and installation.
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <iphoneos|iphonesimulator> <source-inputs> <output> <verified-frameworks>" >&2
    exit 64
fi
sdk=$1; inputs=$2; output=$3; frameworks=$4
case "$sdk" in
    iphoneos) target=arm64-apple-ios16.0 ;;
    iphonesimulator) target=arm64-apple-ios16.0-simulator ;;
    *) echo "Unsupported SDK: $sdk" >&2; exit 64 ;;
esac
recipe=$(cd "$(dirname "$0")" && pwd)
runtime=$(cd "$recipe/.." && pwd)
inputs=$(cd "$inputs" && pwd)
frameworks=$(cd "$frameworks" && pwd)
mkdir -p "$output"
output=$(cd "$output" && pwd)
(cd "$inputs" && shasum -a 256 -c "$recipe/sources.sha256")
for path in ios_system.framework/ios_system openssl.framework/openssl openssl.framework/Headers/opensslv.h; do
    test -f "$frameworks/$path" || { echo "Missing verified framework input: $path" >&2; exit 1; }
done
shasum -a 256 "$frameworks/ios_system.framework/ios_system" "$frameworks/openssl.framework/openssl" > "$output/framework-inputs.sha256"
{
    printf '%s\n' "$sdk" "$target"
    xcodebuild -version
    shasum -a 256 "$recipe/build.sh" "$recipe/embedded.patch" "$recipe/ashell-ssh.h" "$recipe/sources.sha256"
    cat "$output/framework-inputs.sha256"
} > "$output/recipe-next.txt"
if [ -f "$output/recipe.txt" ] && ! cmp -s "$output/recipe.txt" "$output/recipe-next.txt"; then
    echo "Build inputs changed; use a fresh output directory" >&2
    exit 1
fi
mv "$output/recipe-next.txt" "$output/recipe.txt"
if [ ! -d "$output/source" ]; then
    source_stage=$(mktemp -d "$output/source.XXXXXX")
    trap 'rm -rf "$source_stage"' EXIT
    tar -xzf "$inputs/openssh-10.6p1.tar.gz" -C "$source_stage" --strip-components=1
    patch -d "$source_stage" -p1 < "$recipe/embedded.patch"
    mv "$source_stage" "$output/source"
    trap - EXIT
fi
mkdir -p "$output/crypto/include" "$output/crypto/lib" "$output/build"
ln -sfn "$frameworks/openssl.framework/Headers" "$output/crypto/include/openssl"
ln -sfn "$frameworks/openssl.framework/openssl" "$output/crypto/lib/libcrypto.dylib"
cd "$output/build"
if [ ! -f Makefile ]; then
    CC="xcrun --sdk $sdk clang -target $target" "$output/source/configure" --host=aarch64-apple-darwin --with-ssl-dir="$output/crypto" --without-pam --without-libedit --disable-strip --without-sandbox
fi
nice -n 15 make -j2 CFLAGS="-Oz -fPIC -Wno-deprecated-declarations -DASHELL_OPENSSH -I$recipe -I$runtime" LDFLAGS="-dynamiclib -L. -Lopenbsd-compat -F$frameworks -framework ios_system -L$output/crypto/lib" ssh ssh-keygen scp sftp
for pair in 'ssh SSHStock' 'ssh-keygen SSHKeygenStock' 'scp SCPStock' 'sftp SFTPStock'; do
    read -r command name <<< "$pair"
    framework="$output/sdk/$name.framework"
    mkdir -p "$framework"
    cp "$command" "$framework/$name"
    xcrun install_name_tool -id "@rpath/$name.framework/$name" "$framework/$name"
    cat > "$framework/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>CFBundleExecutable</key><string>$name</string><key>CFBundleIdentifier</key><string>org.a-shell.$name</string><key>CFBundleName</key><string>$name</string><key>CFBundlePackageType</key><string>FMWK</string><key>CFBundleVersion</key><string>1</string><key>CFBundleShortVersionString</key><string>10.6p1</string><key>MinimumOSVersion</key><string>16.0</string></dict></plist>
PLIST
    shasum -a 256 "$framework/$name"
done
