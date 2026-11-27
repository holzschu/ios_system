#!/bin/bash
# Compare the real command's public CLI with the installed macOS implementation.
set -eu
command=$1
case "$command" in /*) ;; *) echo "Pass an absolute command path" >&2; exit 2 ;; esac
work=$(mktemp -d /private/tmp/base64-check.XXXXXXXX)
trap 'rm -rf "$work"' EXIT
touch "$work/empty"
printf x > "$work/x"
printf fo > "$work/fo"
printf foo > "$work/foo"
LC_ALL=C awk 'BEGIN { for (i=0; i<256; i++) printf "%c", i }' > "$work/binary"
dd if=/dev/zero of="$work/large" bs=1048576 count=2 2>/dev/null
cat "$work/binary" >> "$work/large"
checks=0
compare() {
    "$command" "$@" < "$input" > "$work/actual" 2> "$work/err"
    /usr/bin/base64 "$@" < "$input" > "$work/expected"
    cmp "$work/actual" "$work/expected"
    test ! -s "$work/err"
    checks=$((checks + 1))
}
for input in "$work/empty" "$work/x" "$work/fo" "$work/foo" "$work/binary" "$work/large"; do
    compare
    for width in 0 1 2 3 4 5 50 76 1023; do
        compare -b "$width"
    done
    compare --break=7
    compare -i "$input"
    "$command" --input "$input" --output "$work/actual-file"
    /usr/bin/base64 -i "$input" -o "$work/expected-file"
    cmp "$work/actual-file" "$work/expected-file"
    "$command" "$input" > "$work/actual-file"
    cmp "$work/actual-file" "$work/expected-file"
    "$command" -e -l50 "$input" "$work/actual-file"
    /usr/bin/base64 -b48 -i "$input" > "$work/expected-file"
    cmp "$work/actual-file" "$work/expected-file"
    /usr/bin/base64 -b7 -i "$input" > "$work/encoded"
    original=$input
    input="$work/encoded"
    compare -d
    compare -D
    compare --decode
    "$command" -d "$input" > "$work/decoded"
    cmp "$work/decoded" "$original"
done
input="$work/x"
compare -i - -o -
printf 'Z g = =\n' > "$work/encoded"
input="$work/encoded"
compare -d
{ printf Z; printf '%4096s' ' '; printf 'g==\n'; } > "$work/encoded"
# macOS itself stalls on this buffer-boundary case; use the known decoded byte.
"$command" -d < "$input" > "$work/actual"
printf f > "$work/expected"
cmp "$work/actual" "$work/expected"
for text in '!!!!' 'Zh==' 'Zm9v!' 'A==='; do
    printf '%s' "$text" > "$work/bad"
    if "$command" -d < "$work/bad" > "$work/actual" 2> "$work/err"; then exit 1; fi
    if /usr/bin/base64 -d < "$work/bad" > "$work/expected" 2> "$work/mac-err"; then exit 1; fi
    cmp "$work/actual" "$work/expected"
    test -s "$work/err"
done
for arg in --bad -b -i -o; do
    if "$command" "$arg" </dev/null > "$work/actual" 2> "$work/err"; then exit 1; fi
    test ! -s "$work/actual"
    test -s "$work/err"
done
for width in -1 abc 4294967296; do
    if "$command" -b "$width" </dev/null > "$work/actual" 2> "$work/err"; then exit 1; fi
    test ! -s "$work/actual"
    test -s "$work/err"
done
if "$command" -i "$work/missing" > "$work/actual" 2> "$work/err"; then exit 1; fi
test ! -s "$work/actual"
test -s "$work/err"
if "$command" -o "$work/missing/out" < "$work/x" > "$work/actual" 2> "$work/err"; then exit 1; fi
test ! -s "$work/actual"
test -s "$work/err"
printf 'keep this file\n' > "$work/protected"
cp "$work/protected" "$work/protected-expected"
if "$command" -i "$work/x" "$work/protected" > "$work/actual" 2> "$work/err"; then exit 1; fi
cmp "$work/protected" "$work/protected-expected"
test ! -s "$work/actual"
test -s "$work/err"
if "$command" -o "$work/actual-file" "$work/x" "$work/protected" > "$work/actual" 2> "$work/err"; then exit 1; fi
cmp "$work/protected" "$work/protected-expected"
if "$command" < "$work/x" >&- 2> "$work/err"; then exit 1; fi
test -s "$work/err"
"$command" -d? > "$work/help" 2> "$work/err"
test -s "$work/help"
test ! -s "$work/err"
if "$command" -i '-?' -z > "$work/actual" 2> "$work/err"; then exit 1; fi
test ! -s "$work/actual"
test -s "$work/err"
"$command" -e -l "$work/x" > "$work/actual"
/usr/bin/base64 -b4 < "$work/x" > "$work/expected"
cmp "$work/actual" "$work/expected"
echo "PASS: $checks macOS byte comparisons, files, legacy aliases and errors"
