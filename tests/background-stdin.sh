#!/bin/sh
# Run through a-Shell's worker-enabled Dash.
set -eu
work=${TMPDIR:-/tmp}/background-stdin-$$
mkdir "$work"
trap 'rm -rf "$work"' EXIT HUP INT TERM
printf 'background input must survive\n' >"$work/input"
setenv ASHELL_WORKER_COMMANDS gzip
gzip -c <"$work/input" >"$work/foreground.gz"
gzip -dc <"$work/foreground.gz" >"$work/foreground"
wc -c <"$work/foreground" >"$work/count"
read bytes <"$work/count"
printf 'Foreground bytes=%s\n' "$bytes"
[ "$bytes" -eq 30 ]
IFS= read -r value <"$work/foreground"
[ "$value" = 'background input must survive' ]
printf '%s\n' 'FOREGROUND_STDIN_PASS'
gzip -c <"$work/input" >"$work/background.gz" &
wait
gzip -dc <"$work/background.gz" >"$work/background"
wc -c <"$work/background" >"$work/count"
read bytes <"$work/count"
printf 'Background bytes=%s\n' "$bytes"
[ "$bytes" -eq 30 ]
IFS= read -r value <"$work/background"
[ "$value" = 'background input must survive' ]
printf '%s\n' 'BACKGROUND_STDIN_PASS'
gzip -c >"$work/inherited.gz" &
wait
gzip -dc <"$work/inherited.gz" >"$work/inherited"
wc -c <"$work/inherited" >"$work/count"
read bytes <"$work/count"
[ "$bytes" -eq 0 ]
printf '%s\n' 'INHERITED_BACKGROUND_STDIN_PASS'
