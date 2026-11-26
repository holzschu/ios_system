#!/usr/bin/env bash
set -euo pipefail

if [[ $# != 1 ]]; then
    echo 'Usage: bash ci/auxiliary/test-make-job-dispatch.sh MAKE_ZIP' >&2
    exit 2
fi

work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
binary=make.xcframework/ios-arm64/make.framework/make
unzip -q "$1" "$binary" -d "$work"
xcrun llvm-objdump --macho --arch=arm64 --disassemble-symbols=_JobExec "$work/$binary" |
    awk '
        /^_JobExec:$/ { in_job = 1; next }
        /^_[^[:space:]]+:$/ { in_job = 0 }
        !in_job { next }
        /symbol stub for: _vfork$/ { fork_seen = 1 }
        !fork_seen { next }
        /[[:space:]]cbn?z[[:space:]]+w0,/ && !dispatch { zero_guard = 1 }
        /[[:space:]]cmn[[:space:]]+w0, #0x1$/ && !dispatch { failure_guard = 1 }
        /[[:space:]]b\.eq[[:space:]]/ && failure_guard && !dispatch { failure_branch = 1 }
        /symbol stub for: _ios_execv$/ { dispatch = 1 }
        /[[:space:]]bl[[:space:]]+_Trace_Log$/ && !dispatch { parent_first = 1 }
        END {
            if (!fork_seen || !failure_guard || !failure_branch || zero_guard || !dispatch || parent_first) {
                print "FAIL: expected JobExec to reject only the -1 fork result before recipe dispatch" > "/dev/stderr"
                exit 1
            }
            print "PASS: JobExec dispatches a recipe before parent bookkeeping on a positive logical PID"
        }
    '
