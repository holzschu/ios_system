#!/bin/bash
# Build the Auxiliary FFmpeg commands and their source dependencies.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")" && pwd)
WORK="$ROOT/.build/ffmpeg"
JOBS=${JOBS:-4}
SDK=${1:-all}
case "$SDK" in all|iphoneos|iphonesimulator) ;; *) echo "usage: $0 [all|iphoneos|iphonesimulator]" >&2; exit 2;; esac
METAL=$(xcrun --sdk macosx -f metal)
# The companion linker is shipped beside metal, including in Apple's cryptex.
METALLIB="$(dirname "$METAL")/metallib"
[ -x "$METALLIB" ] || { echo 'The installed Metal toolchain has no metallib.' >&2; exit 1; }
mkdir -p "$WORK/downloads" "$WORK/source" "$WORK/output"

fetch() {
  local file=$1 sum=$2 url=$3
  if [ ! -f "$WORK/downloads/$file" ]; then
    curl --fail --location --retry 3 "$url" -o "$WORK/downloads/$file.tmp"
    echo "$sum  $WORK/downloads/$file.tmp" | shasum -a 256 -c -
    mv "$WORK/downloads/$file.tmp" "$WORK/downloads/$file"
  fi
  echo "$sum  $WORK/downloads/$file" | shasum -a 256 -c -
}

fetch ffmpeg.tar.gz 0eed411e3cd8bc3f740208b7120a21909bdf767a6df026e9fcbc11cf10edb8b0 https://codeload.github.com/FFmpeg/FFmpeg/tar.gz/a5ebb3d25e50c6f59f931115fb18121032dfa12d
fetch freetype.tar.gz e09aa914e4f7a5d723ac381420949c55c0b90b15744adce5d1406046022186ab https://download.savannah.gnu.org/releases/freetype/freetype-2.10.2.tar.gz
fetch zimg.tar.gz a3615c18459ce7a835a9b56106dea967985150461dc0fb3b6d484befd7bb506d https://codeload.github.com/sekrit-twc/zimg/tar.gz/43daaf1c50f57d989ed683330c40811457df6329
fetch openssl.tar.gz cf3098950cb4d853ad95c0841f1f9c6d3dc102dccfcacd521d93925208b76ac8 https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1w/openssl-1.1.1w.tar.gz
fetch ios_system.zip d429e68102926f58bedd8e8b7105dcd169478cd6da1cef494a5f468482d1c8f5 https://github.com/holzschu/ios_system/releases/download/v3.0.5/ios_system.xcframework.zip
fetch ios_error.h 51d46b912eb30399cbb5c36c8c8f15eb1a44adcfc9ee581304ac9d3739a84716 https://github.com/holzschu/ios_system/releases/download/v3.0.5/ios_error.h

for archive in ffmpeg freetype zimg; do
  if [ ! -d "$WORK/source/$archive" ]; then
    mkdir -p "$WORK/source/$archive"
    tar -xzf "$WORK/downloads/$archive.tar.gz" --strip-components=1 -C "$WORK/source/$archive"
  fi
done
# Prevent version.sh from picking up this enclosing ios_system checkout.
echo n5.0.1-4-ga5ebb3d25e > "$WORK/source/ffmpeg/VERSION"
# Redirect command stderr while leaving library descriptor I/O unchanged.
if ! grep -Fq 'ret = ios_write(2/*STDERR_FILENO*/' "$WORK/source/ffmpeg/fftools/ffmpeg.c"; then
  patch -d "$WORK/source/ffmpeg" -p1 <<'PATCH'
--- a/fftools/ffmpeg.c
+++ b/fftools/ffmpeg.c
@@ -355,7 +355,7 @@
     received_nb_signals++;
     term_exit_sigsafe();
     if(received_nb_signals > 3) {
-        ret = write(2/*STDERR_FILENO*/, "Received > 3 system signals, hard exiting\n",
+        ret = ios_write(2/*STDERR_FILENO*/, "Received > 3 system signals, hard exiting\n",
                     strlen("Received > 3 system signals, hard exiting\n"));
         if (ret < 0) { /* Do nothing */ };
         exit(123);
PATCH
fi
if ! grep -Fq 'FILE *ffmpeg_stdin;' "$WORK/source/ffmpeg/fftools/cmdutils.c"; then
  patch -d "$WORK/source/ffmpeg" -p1 <<'PATCH'
--- a/fftools/cmdutils.c
+++ b/fftools/cmdutils.c
@@ -25,6 +25,10 @@
 #include <errno.h>
 #include <math.h>
-
+
+FILE *ffmpeg_stdin;
+FILE *ffmpeg_stdout;
+FILE *ffmpeg_stderr;
+
 /* Include only the enabled headers since some compilers (namely, Sun
    Studio) will not omit unused inline functions and create undefined
    references to libraries that are not being built. */
--- a/fftools/ffmpeg.c
+++ b/fftools/ffmpeg.c
@@ -4845,6 +4845,10 @@
     int i, ret;
     BenchmarkTimeStamps ti;
-
+
+    ffmpeg_stdin = thread_stdin;
+    ffmpeg_stdout = thread_stdout;
+    ffmpeg_stderr = thread_stderr;
+
     init_dynload();
-
+
     register_exit(ffmpeg_cleanup);
--- a/fftools/ffprobe.c
+++ b/fftools/ffprobe.c
@@ -3873,6 +3873,10 @@
     char *w_name = NULL, *w_args = NULL;
     int ret, i;
-
+
+    ffmpeg_stdin = thread_stdin;
+    ffmpeg_stdout = thread_stdout;
+    ffmpeg_stderr = thread_stderr;
+
     init_dynload();
-
+
 #if HAVE_THREADS
PATCH
fi
[ -d "$WORK/ios_system.xcframework" ] || unzip -q "$WORK/downloads/ios_system.zip" -d "$WORK"
if [ ! -f "$WORK/source/zimg/configure" ]; then
  (cd "$WORK/source/zimg" && ./autogen.sh)
fi

# Include system declarations before ios_system's function redirections.
cat > "$WORK/ios-stdio.h.tmp" <<'HEADER'
#include <stdlib.h>
#include <wchar.h>
#include <signal.h>
#include "downloads/ios_error.h"
extern FILE *ffmpeg_stdin;
extern FILE *ffmpeg_stdout;
extern FILE *ffmpeg_stderr;
// Library descriptor writes and callback members must keep their own names.
#undef write
#undef stdin
#undef stdout
#undef stderr
#define stdin ffmpeg_stdin
#define stdout ffmpeg_stdout
#define stderr ffmpeg_stderr
#define printf(...) fprintf(ffmpeg_stdout, __VA_ARGS__)
HEADER
if ! cmp -s "$WORK/ios-stdio.h.tmp" "$WORK/ios-stdio.h"; then
  mv "$WORK/ios-stdio.h.tmp" "$WORK/ios-stdio.h"
fi
rm -f "$WORK/ios-stdio.h.tmp"

framework() {
  local name=$1; shift
  local version
  case "$name" in freetype) version=2.10.2;; openssl) version=1.1.1;; *) version=5.0.1;; esac
  local dest="$frameworks/$name.framework"
  mkdir -p "$dest"
  "$cc" -dynamiclib $flags -Wl,-all_load "$@" \
    -install_name "@rpath/$name.framework/$name" -lz -lc++ -o "$dest/$name"
  cat > "$dest/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>$name</string>
<key>CFBundleIdentifier</key><string>AsheKube.$name</string>
<key>CFBundleName</key><string>$name</string>
<key>CFBundlePackageType</key><string>FMWK</string>
<key>CFBundleShortVersionString</key><string>$version</string>
<key>CFBundleVersion</key><string>1</string>
<key>MinimumOSVersion</key><string>14.0</string>
<key>CFBundleSupportedPlatforms</key><array><string>$platform</string></array>
</dict></plist>
PLIST
}

for target in iphoneos-arm64 iphonesimulator-arm64 iphonesimulator-x86_64; do
  sdk=${target%-*}
  [ "$SDK" = all ] || [ "$SDK" = "$sdk" ] || continue
  case "$sdk" in
    iphoneos) arch=arm64; triple=arm64-apple-ios14.0; host=aarch64-apple-darwin; ssl_target=ios64-xcrun; platform=iPhoneOS; ios_slice=ios-arm64;;
    iphonesimulator) arch=${target##*-}; triple=$arch-apple-ios14.0-simulator; host=$arch-apple-darwin; ssl_target=iossimulator-xcrun; platform=iPhoneSimulator; ios_slice=ios-arm64_x86_64-simulator;;
  esac
  [ "$arch" != arm64 ] || host=aarch64-apple-darwin
  sysroot=$(xcrun --sdk "$sdk" --show-sdk-path)
  cc=$(xcrun --sdk "$sdk" -f clang)
  cxx=$(xcrun --sdk "$sdk" -f clang++)
  flags="-target $triple -isysroot $sysroot -fPIC -O2"
  build="$WORK/$target"
  prefix="$build/prefix"
  frameworks="$WORK/output/$target"
  mkdir -p "$build" "$prefix/lib/pkgconfig" "$frameworks"

  # Keep dependency discovery confined to this target's staging directory.
  export PKG_CONFIG_LIBDIR="$prefix/lib/pkgconfig" PKG_CONFIG_PATH=
  cmake -S "$WORK/source/freetype" -B "$build/freetype" -G Ninja \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 -DCMAKE_SYSTEM_NAME=iOS \
    -DCMAKE_OSX_SYSROOT="$sysroot" -DCMAKE_OSX_ARCHITECTURES="$arch" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET=14.0 -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$prefix" -DBUILD_SHARED_LIBS=OFF \
    -DFT_WITH_ZLIB=ON -DCMAKE_DISABLE_FIND_PACKAGE_HarfBuzz=TRUE \
    -DCMAKE_DISABLE_FIND_PACKAGE_PNG=TRUE -DCMAKE_DISABLE_FIND_PACKAGE_BZip2=TRUE \
    -DCMAKE_DISABLE_FIND_PACKAGE_BrotliDec=TRUE
  cmake --build "$build/freetype" --parallel "$JOBS"
  cmake --install "$build/freetype"
  framework freetype "$prefix/lib/libfreetype.a"

  mkdir -p "$build/zimg"
  (cd "$build/zimg"
    CC="$cc" CXX="$cxx" CFLAGS="$flags" CXXFLAGS="$flags" LDFLAGS="$flags" STL_LIBS=-lc++ \
      "$WORK/source/zimg/configure" --host="$host" --prefix="$prefix" --disable-shared --enable-static
    make -j "$JOBS"
    make install
  )
  xcrun libtool -static -o "$frameworks/libzimg.a" "$prefix/lib/libzimg.a"
  mkdir -p "$frameworks/zimg-headers"
  cp "$prefix/include/zimg.h" "$frameworks/zimg-headers/"

  if [ ! -f "$build/openssl/Configure" ]; then
    mkdir -p "$build/openssl"
    tar -xzf "$WORK/downloads/openssl.tar.gz" --strip-components=1 -C "$build/openssl"
  fi
  (cd "$build/openssl"
    CC="$cc" CFLAGS="$flags" ./Configure "$ssl_target" no-shared no-asm no-tests --prefix="$prefix" --openssldir=/etc/ssl
    make -j "$JOBS" build_libs
  )
  framework openssl "$build/openssl/libssl.a" "$build/openssl/libcrypto.a"

  # Advertise the framework dependencies rather than their static source archives.
  for name in freetype2 openssl; do
    case "$name" in
      freetype2) version=23.2.17; lib=freetype; includes="$prefix/include/freetype2";;
      openssl) version=1.1.1w; lib=openssl; includes="$build/openssl/include";;
    esac
    cat > "$prefix/lib/pkgconfig/$name.pc" <<PC
Name: $name
Description: $name for $sdk
Version: $version
Libs: -F$frameworks -framework $lib
Cflags: -I$includes
PC
  done
  mkdir -p "$build/ffmpeg"
  (cd "$build/ffmpeg"
    "$WORK/source/ffmpeg/configure" --cc="$cc" --cxx="$cxx" --arch="$arch" --target-os=darwin \
      --disable-asm --enable-cross-compile --enable-pthreads --enable-videotoolbox \
      --disable-audiotoolbox --enable-openssl --enable-libfreetype --enable-libzimg \
      --enable-network --disable-debug --disable-gpl --disable-nonfree --disable-doc --disable-ffplay \
      --sysroot="$sysroot" --pkg-config="$(command -v pkg-config)" --pkg-config-flags=--static \
      --metalcc="$METAL -target air64-${triple#*-} -isysroot $sysroot -fmodules-cache-path=$build/metal-cache" \
      --metallib="$METALLIB" \
      --extra-cflags="$flags -D_DARWIN_C_SOURCE=1 -include $WORK/ios-stdio.h" \
      --extra-ldflags="$flags -F$frameworks -F$WORK/ios_system.xcframework/$ios_slice" \
      --extra-libs='-framework ios_system -lc++'
    make -j "$JOBS" ffmpeg ffprobe
    for name in ffmpeg ffprobe; do
      # Relink the normal CLI objects as the framework's main entry point.
      case "$name" in ffmpeg) objects='fftools/ffmpeg.o fftools/ffmpeg_opt.o fftools/ffmpeg_filter.o fftools/ffmpeg_hw.o';; ffprobe) objects='fftools/ffprobe.o';; esac
      framework "$name" $objects fftools/cmdutils.o \
        libavdevice/libavdevice.a libavfilter/libavfilter.a libavformat/libavformat.a \
        libavcodec/libavcodec.a libswresample/libswresample.a libswscale/libswscale.a libavutil/libavutil.a \
        "$prefix/lib/libzimg.a" -F"$frameworks" -framework freetype -framework openssl \
        -F"$WORK/ios_system.xcframework/$ios_slice" -framework ios_system \
        -framework Foundation -framework AVFoundation -framework CoreVideo -framework CoreMedia \
        -framework Metal -framework VideoToolbox -framework CoreFoundation -lbz2 -liconv
    done
    cp config.h "$frameworks/ffmpeg-config.h"
    cp ffbuild/config.log "$frameworks/ffmpeg-config.log"
  )
done

[ "$SDK" = all ] || exit 0
for name in ffmpeg ffprobe freetype openssl; do
  rm -rf "$WORK/output/iphonesimulator/$name.framework"
  mkdir -p "$WORK/output/iphonesimulator"
  cp -R "$WORK/output/iphonesimulator-arm64/$name.framework" "$WORK/output/iphonesimulator/"
  lipo -create "$WORK/output/iphonesimulator-arm64/$name.framework/$name" \
    "$WORK/output/iphonesimulator-x86_64/$name.framework/$name" \
    -output "$WORK/output/iphonesimulator/$name.framework/$name"
done
lipo -create "$WORK/output/iphonesimulator-arm64/libzimg.a" "$WORK/output/iphonesimulator-x86_64/libzimg.a" -output "$WORK/output/iphonesimulator/libzimg.a"
cp -R "$WORK/output/iphonesimulator-arm64/zimg-headers" "$WORK/output/iphonesimulator/"
for name in ffmpeg ffprobe freetype openssl; do
  rm -rf "$WORK/output/$name.xcframework"
  xcodebuild -create-xcframework -framework "$WORK/output/iphoneos-arm64/$name.framework" \
    -framework "$WORK/output/iphonesimulator/$name.framework" -output "$WORK/output/$name.xcframework"
done
rm -rf "$WORK/output/zimg.xcframework"
xcodebuild -create-xcframework -library "$WORK/output/iphoneos-arm64/libzimg.a" -headers "$WORK/output/iphoneos-arm64/zimg-headers" \
  -library "$WORK/output/iphonesimulator/libzimg.a" -headers "$WORK/output/iphonesimulator/zimg-headers" -output "$WORK/output/zimg.xcframework"
(cd "$WORK/output"
  for name in ffmpeg ffprobe freetype openssl zimg; do
    rm -f "$name.xcframework.zip"
    zip -rq "$name.xcframework.zip" "$name.xcframework"
    sum=$(swift package compute-checksum "$name.xcframework.zip")
    echo "$sum  $name.xcframework.zip"
  done | tee checksums.txt
  cp checksums.txt release.md
)
