#!/bin/bash
set -euo pipefail
export LC_ALL=C
if [[ $# != 4 ]]; then
    echo 'Usage: bash ci/auxiliary/audit-exports.sh make|mandoc|unrar candidate.zip published.zip ios_system.zip' >&2
    exit 2
fi
product=$1
artifact=$2
baseline=$3
dependency=$4
script_dir=$(cd "$(dirname "$0")" && pwd)
case "$product" in
    make) sha=6f9dca82bfdee1be8ad0ec1e52870bee6b3e309ac29f0995a6d5a41003c26d4f; count=268 ;;
    mandoc) sha=86428238cb357ece2da6b813fe493dfcee1f4efc91ec535d73b3e581d9b8e21b; count=267 ;;
    unrar) sha=b1c2318db3b89a668abd66f69036ec9c3c5d474b2d75a0b1ffbaf2ac47b02782; count=615 ;;
    *) echo "Unexpected component: $product" >&2; exit 2 ;;
esac
printf '%s  %s\n' "$sha" "$baseline" | shasum -a 256 -c -
temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT
unzip -q "$artifact" -d "$temporary/candidate"
unzip -q "$baseline" -d "$temporary/published"
printf '%s  %s\n' d429e68102926f58bedd8e8b7105dcd169478cd6da1cef494a5f468482d1c8f5 "$dependency" | shasum -a 256 -c -
unzip -q "$dependency" -d "$temporary/dependency"
root="$temporary/candidate/$product.xcframework"
plist=/usr/libexec/PlistBuddy
{
    $plist -c 'Print :AvailableLibraries:0:LibraryIdentifier' "$root/Info.plist"
    $plist -c 'Print :AvailableLibraries:1:LibraryIdentifier' "$root/Info.plist"
} | LC_ALL=C sort > "$temporary/identifiers.txt"
printf '%s\n' ios-arm64 ios-arm64_x86_64-simulator > "$temporary/expected-identifiers.txt"
diff -u "$temporary/expected-identifiers.txt" "$temporary/identifiers.txt"
if $plist -c 'Print :AvailableLibraries:2' "$root/Info.plist" >/dev/null 2>&1; then
    echo 'Unexpected third xcframework slice.' >&2
    exit 1
fi
for slice in ios-arm64 ios-arm64_x86_64-simulator; do
    binary="$root/$slice/$product.framework/$product"
    expected=arm64
    platform=IOS
    if [[ $slice == *simulator ]]; then expected='arm64 x86_64'; platform=IOSSIMULATOR; fi
    actual=$(xcrun lipo -archs "$binary" | tr ' ' '\n' | LC_ALL=C sort | paste -sd ' ' -)
    test "$actual" = "$expected"
    for arch in $expected; do
        old="$temporary/published/$product.xcframework/ios-arm64/$product.framework/$product"
        expected_count=$count
        if [[ $product == unrar && $arch == x86_64 ]]; then
            old="$temporary/published/unrar.xcframework/ios-x86_64-simulator/unrar.framework/unrar"
            expected_count=617
        fi
        old_arch=arm64
        if [[ $product == unrar && $arch == x86_64 ]]; then old_arch=x86_64; fi
        xcrun nm -arch "$old_arch" -gjU "$old" | LC_ALL=C sort -u > "$temporary/expected.txt"
        test "$(wc -l < "$temporary/expected.txt" | tr -d ' ')" = "$expected_count"
        xcrun nm -arch "$arch" -gjU "$binary" | LC_ALL=C sort -u > "$temporary/actual.txt"
        diff -u "$temporary/expected.txt" "$temporary/actual.txt"
        # Export-name equality does not verify the imported host contract.
        xcrun nm -arch "$old_arch" -uj "$old" | LC_ALL=C sort -u > "$temporary/old-imports.txt"
        xcrun nm -arch "$arch" -uj "$binary" | LC_ALL=C sort -u > "$temporary/new-imports.txt"
        comm -13 "$temporary/old-imports.txt" "$temporary/new-imports.txt" > "$temporary/add.txt"
        comm -23 "$temporary/old-imports.txt" "$temporary/new-imports.txt" > "$temporary/remove.txt"
        for change in add remove; do
            while IFS= read -r symbol; do
                awk -F '\t' -v product="$product" -v change="$change" -v symbol="$symbol" '
                    $1 == product && $2 == change && $3 == symbol {found=1}
                    END {exit !found}' "$script_dir/import-changes.tsv" || {
                    echo "Unreviewed import $change: $product $arch $symbol" >&2; exit 1;
                }
                printf 'REVIEWED_IMPORT_%s %s %s %s\n' "$change" "$product" "$arch" "$symbol"
            done < "$temporary/$change.txt"
        done
        runtime="$temporary/dependency/ios_system.xcframework/$slice/ios_system.framework/ios_system"
        xcrun nm -arch "$arch" -gjU "$runtime" | LC_ALL=C sort -u > "$temporary/runtime-exports.txt"
        xcrun nm -arch "$arch" -mu "$binary" | awk '$NF == "ios_system)" {print $(NF-2)}' | LC_ALL=C sort -u > "$temporary/runtime-imports.txt"
        comm -23 "$temporary/runtime-imports.txt" "$temporary/runtime-exports.txt" > "$temporary/missing-runtime.txt"
        if [[ -s $temporary/missing-runtime.txt ]]; then
            echo 'Unresolved imports against the pinned consumer ios_system:' >&2
            cat "$temporary/missing-runtime.txt" >&2
            exit 1
        fi
        echo "IOS_SYSTEM_IMPORT_CLOSURE_PASS $product $slice $arch"
        xcrun vtool -arch "$arch" -show-build "$binary" > "$temporary/load.txt"
        test "$(awk '$1 == "minos" {print $2}' "$temporary/load.txt")" = 14.0
        test "$(awk '$1 == "platform" {print $2}' "$temporary/load.txt")" = "$platform"
        xcrun otool -arch "$arch" -L "$binary" | awk '/^\t/ {print $1}' > "$temporary/dependencies.txt"
        while IFS= read -r dependency; do
            case "$dependency" in
                "@rpath/$product.framework/$product"|@rpath/ios_system.framework/ios_system|/usr/lib/libSystem.B.dylib) ;;
                /usr/lib/libz.1.dylib) test "$product" = mandoc ;;
                /usr/lib/libc++.1.dylib) test "$product" = unrar ;;
                *) echo "Unexpected dependency: $dependency" >&2; exit 1 ;;
            esac
        done < "$temporary/dependencies.txt"
        printf 'PASS: %s %s %s, minimum14, %s published exports\n' "$product" "$slice" "$arch" "$expected_count"
    done
done
