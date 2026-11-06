#!/bin/sh
# Run through a-Shell's worker-enabled Dash. A worker that answers while it is still reading must not stall.
set -eu
work=${TMPDIR:-/tmp}/worker-pipeline-$$
mkdir "$work"
trap 'rm -rf "$work"' EXIT HUP INT TERM
head -c 2000000 /dev/urandom >"$work/input"
setenv ASHELL_WORKER_COMMANDS ""
gzip -c <"$work/input" | wc -c >"$work/expected"
read expected <"$work/expected"
setenv ASHELL_WORKER_COMMANDS "gzip wc"
gzip -c <"$work/input" | wc -c >"$work/count"
read bytes <"$work/count"
printf 'Worker gzip, redirected input, bytes=%s expected=%s\n' "$bytes" "$expected"
[ "$bytes" -eq "$expected" ]
printf '%s\n' 'WORKER_REDIRECT_PIPE_PASS'
cat "$work/input" | gzip -c | wc -c >"$work/count"
read bytes <"$work/count"
printf 'Worker gzip behind a pipe, bytes=%s expected=%s\n' "$bytes" "$expected"
[ "$bytes" -eq "$expected" ]
printf '%s\n' 'WORKER_PIPE_INPUT_PASS'
