#!/bin/bash
# Compare the packaged command ABI and configuration with the published assets.
set -euo pipefail
export LC_ALL=C
ROOT=$(cd "$(dirname "$0")" && pwd)
OUTPUT=${1:-"$ROOT/.build/ffmpeg/output"}
BASELINE="$ROOT/.build/ffmpeg/baseline"
mkdir -p "$BASELINE" "$OUTPUT/comparison"
for name in ffmpeg ffprobe; do
  case "$name" in
    ffmpeg) sum=627a9392a8d4704e4e04636692e3baeacb7af4f273e61fe676270aa16b1ef371;;
    ffprobe) sum=c66df5198becb1e0432c27c8f0df628fa185224c9f0bcff2039e3bd21246b130;;
  esac
  archive="$BASELINE/$name.xcframework.zip"
  if [ ! -f "$archive" ]; then
    curl --fail --location --retry 3 "https://github.com/holzschu/ios_system/releases/download/Auxiliary/$name.xcframework.zip" -o "$archive.tmp"
    echo "$sum  $archive.tmp" | shasum -a 256 -c -
    mv "$archive.tmp" "$archive"
  fi
  echo "$sum  $archive" | shasum -a 256 -c -
  [ -d "$BASELINE/$name.xcframework" ] || unzip -q "$archive" -d "$BASELINE"
  for slice in ios-arm64 ios-x86_64-simulator; do
    old="$BASELINE/$name.xcframework/$slice/$name.framework/$name"
    new="$OUTPUT/$name.xcframework/$slice/$name.framework/$name"
    [ -f "$new" ] || { echo "Missing $new" >&2; exit 1; }
    report="$OUTPUT/comparison/$name-$slice"
    nm -gjU "$old" | sort -u > "$report.published-symbols.txt"
    nm -gjU "$new" | sort -u > "$report.built-symbols.txt"
    comm -23 "$report.published-symbols.txt" "$report.built-symbols.txt" > "$report.removed-symbols.txt"
    comm -13 "$report.published-symbols.txt" "$report.built-symbols.txt" > "$report.added-symbols.txt"
    [ ! -s "$report.removed-symbols.txt" ] || { cat "$report.removed-symbols.txt" >&2; exit 1; }
    grep -qx _main "$report.built-symbols.txt" || { echo "Missing main in $name/$slice" >&2; exit 1; }
    strings "$old" | grep '^--cc=' > "$report.published-config.txt"
    strings "$new" | grep '^--cc=' > "$report.built-config.txt"
    # Compiler paths, sysroots and architecture are toolchain-specific. Preserve
    # every published feature switch; doc/ffplay packaging switches are separate.
    built_config=" $(cat "$report.built-config.txt") "
    for flag in $(cat "$report.published-config.txt"); do
      case "$flag" in
        --enable-*|--disable-*)
          case "$built_config" in *" $flag "*) ;; *) echo "Missing published switch $flag in $name/$slice" >&2; exit 1;; esac
          ;;
      esac
    done
    nm -guj "$new" > "$report.imports.txt"
    for symbol in _ios_exit _thread_stdout; do
      grep -qx "$symbol" "$report.imports.txt" || { echo "Missing import $symbol in $name/$slice" >&2; exit 1; }
    done
    otool -L "$new" | tail -n +2 > "$report.dependencies.txt"
    if grep -E '/(Users|opt/homebrew|usr/local)/|\.build/' "$report.dependencies.txt"; then exit 1; fi
    case "$slice" in ios-arm64) arch=arm64;; ios-x86_64-simulator) arch=x86_64;; esac
    [ "$(lipo -archs "$new")" = "$arch" ] || { echo "Wrong architecture in $name/$slice" >&2; exit 1; }
  done
done
echo 'Published FFmpeg configuration and exported-symbol checks pass.'
