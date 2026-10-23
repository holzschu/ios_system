#!/bin/bash
# Compare the packaged command ABI and configuration with the published assets.
set -euo pipefail
export LC_ALL=C
ROOT=$(cd "$(dirname "$0")" && pwd)
OUTPUT=${1:-"$ROOT/.build/ffmpeg/output"}
BASELINE="$ROOT/.build/ffmpeg/baseline"
mkdir -p "$BASELINE" "$OUTPUT/comparison"
# Validate every product before comparing the two command frameworks.
for name in ffmpeg ffprobe freetype openssl zimg; do
  xcf="$OUTPUT/$name.xcframework"
  plutil -convert json -o - "$xcf/Info.plist" | jq -e '
    [.AvailableLibraries[] | {id: .LibraryIdentifier, archs: (.SupportedArchitectures | sort)}] | sort_by(.id) ==
    [{id: "ios-arm64", archs: ["arm64"]}, {id: "ios-arm64_x86_64-simulator", archs: ["arm64", "x86_64"]}]' >/dev/null
  while IFS=$'\t' read -r slice lib expected; do
    bin="$xcf/$slice/$lib"
    case "$lib" in *.framework) bin="$bin/$(basename "${lib%.framework}")";; esac
    test "$(lipo -archs "$bin" | tr ' ' '\n' | sort | paste -sd ' ' -)" = "$expected"
    case "$slice" in ios-arm64) platform=2;; *) platform=7;; esac
    for arch in $expected; do
      otool -arch "$arch" -l "$bin" | awk -v expected="$platform" '
        $1 == "platform" { seen++; if ($2 != expected) bad=1 }
        END { exit (!seen || bad) }'
    done
  done < <(plutil -convert json -o - "$xcf/Info.plist" | jq -r '.AvailableLibraries[] | [.LibraryIdentifier,.LibraryPath,(.SupportedArchitectures|sort|join(" "))] | @tsv')
done
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
  for target in ios-arm64:arm64 ios-arm64_x86_64-simulator:arm64 ios-arm64_x86_64-simulator:x86_64; do
    slice=${target%:*}
    arch=${target##*:}
    old_slice=$slice
    [ "$slice" != ios-arm64_x86_64-simulator ] || old_slice=ios-x86_64-simulator
    old="$BASELINE/$name.xcframework/$old_slice/$name.framework/$name"
    new="$OUTPUT/$name.xcframework/$slice/$name.framework/$name"
    [ -f "$new" ] || { echo "Missing $new" >&2; exit 1; }
    report="$OUTPUT/comparison/$name-$slice-$arch"
    nm -gjU "$old" | sort -u > "$report.published-symbols.txt"
    nm -arch "$arch" -gjU "$new" | sort -u > "$report.built-symbols.txt"
    comm -23 "$report.published-symbols.txt" "$report.built-symbols.txt" > "$report.removed-symbols.txt"
    comm -13 "$report.published-symbols.txt" "$report.built-symbols.txt" > "$report.added-symbols.txt"
    [ ! -s "$report.removed-symbols.txt" ] || { cat "$report.removed-symbols.txt" >&2; exit 1; }
    grep -qx _main "$report.built-symbols.txt" || { echo "Missing main in $name/$slice/$arch" >&2; exit 1; }
    strings "$old" | grep '^--cc=' > "$report.published-config.txt"
    if [ "$slice" = ios-arm64 ]; then
      cp "$new" "$report.binary"
    else
      lipo "$new" -thin "$arch" -output "$report.binary"
    fi
    strings "$report.binary" | grep '^--cc=' > "$report.built-config.txt"
    # Compiler paths, sysroots and architecture are toolchain-specific. Preserve
    # every published feature switch; doc/ffplay packaging switches are separate.
    built_config=" $(cat "$report.built-config.txt") "
    for flag in $(cat "$report.published-config.txt"); do
      case "$flag" in
        --enable-*|--disable-*)
          case "$built_config" in *" $flag "*) ;; *) echo "Missing published switch $flag in $name/$slice/$arch" >&2; exit 1;; esac
          ;;
      esac
    done
    nm -arch "$arch" -guj "$new" > "$report.imports.txt"
    for symbol in _ios_exit _thread_stdout; do
      grep -qx "$symbol" "$report.imports.txt" || { echo "Missing import $symbol in $name/$slice/$arch" >&2; exit 1; }
    done
    rm -f "$report.binary"
    otool -arch "$arch" -L "$new" | tail -n +2 > "$report.dependencies.txt"
    if grep -E '/(Users|opt/homebrew|usr/local)/|\.build/' "$report.dependencies.txt"; then exit 1; fi
    case "$slice" in ios-arm64) expected=arm64;; *) expected="arm64 x86_64";; esac
    [ "$(lipo -archs "$new" | tr ' ' '\n' | sort | paste -sd ' ' -)" = "$expected" ] || { echo "Wrong architecture in $name/$slice/$arch" >&2; exit 1; }
  done
done
echo 'Published FFmpeg configuration and exported-symbol checks pass.'
