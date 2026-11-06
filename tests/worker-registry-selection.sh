#!/bin/dash
# Run in a disposable worker-enabled host with a PATH-first git wrapper that prints
# DISPATCH_WRAPPER_SELECTED, and pass the absolute zero-byte native git marker.
set -eu
native_git=${1:?Pass the absolute native git marker}
test "$(git --version)" = DISPATCH_WRAPPER_SELECTED
case "$("$native_git" --version)" in
	'git version '*) ;;
	*) echo 'Explicit native Git selection was lost during worker dispatch' >&2; exit 1 ;;
esac
echo WORKER_REGISTRY_SELECTION_PASS
