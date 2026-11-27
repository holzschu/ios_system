#!/bin/sh
# Run in a-Shell with a files.framework carrying this change, from a writable directory.
set -eu
mkdir base64-device-check
cd base64-device-check
printf 'eA==\n' > expected
printf x | base64 > actual
diff expected actual
printf 'x' > x
base64 x | base64 -d > decoded
diff x decoded
base64 -d -i actual -o decoded
diff x decoded
printf 'e\nA\n=\n=\n' > expected
printf x | base64 -b 1 > actual
diff expected actual
printf '\000\001\177\200\377' > binary
printf 'AAF/gP8=\n' > expected
base64 --input binary --output actual
diff expected actual
base64 --decode actual > decoded
diff binary decoded
base64 -e -l4 binary legacy
printf 'AAF/\ngP8=\n' > expected
diff expected legacy
base64 -D legacy decoded
diff binary decoded
printf '!!!!\n' > bad
if base64 -d bad > actual 2> error; then exit 1; fi
test ! -s actual
test -s error
printf 'keep this file\n' > protected
cp protected protected-expected
if base64 -i x protected > actual 2> error; then exit 1; fi
diff protected protected-expected
test ! -s actual
test -s error
if base64 -i missing > actual 2> error; then exit 1; fi
test ! -s actual
test -s error
if base64 --bad > actual 2> error; then exit 1; fi
test ! -s actual
test -s error
# Re-enter after decoding, wrapping and failures in the same command image.
printf x | base64 > actual
printf 'eA==\n' > expected
diff expected actual
base64 -d actual > decoded
diff x decoded
echo 'PASS: base64 stdin/stdout, binary, wrap, files, errors and re-entry'
