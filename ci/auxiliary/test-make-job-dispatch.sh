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
here=$(cd "$(dirname "$0")" && pwd)
check="$here/check-make-job-dispatch.awk"
xcrun otool -arch arm64 -tvV "$work/$binary" > "$work/device.s"
awk -f "$check" "$work/device.s"

# Mutate one instruction in each copy of the real disassembly.
awk -v unrelated="$work/unrelated.s" -v bypass="$work/bypass.s" '
    /^_JobExec:$/ { in_job = 1 }
    in_job && /^_[^[:space:]]+:$/ && !/^_JobExec:$/ { exit }
    !in_job { next }
    {
        original[++n] = $0
        if ($0 ~ /symbol stub for: _fork$/)
            fork_seen = 1
        if (!compare && fork_seen && $0 ~ /[[:space:]]cmn[[:space:]]+w0, #0x1$/)
            compare = n
        if (!jump && compare && $2 == "cbz" && $NF ~ /^0x[[:xdigit:]]+$/)
            jump = n
        if (after_exec == -1) {
            after_exec = $1
            sub(/^0+/, "", after_exec)
        }
        if ($0 ~ /symbol stub for: _ios_execv$/)
            after_exec = -1
    }
    END {
        if (!compare || !jump || !after_exec || after_exec == -1)
            exit 1
        for (i = 1; i <= n; i++) {
            row = original[i]
            if (i == compare)
                sub(/w0, #0x1$/, "w30, #0x1", row)
            print row > unrelated
            row = original[i]
            if (i == jump)
                sub(/0x[[:xdigit:]]+$/, "0x" after_exec, row)
            print row > bypass
        }
    }
' "$work/device.s"

reject_fixture() {
    local name=$1 diagnostic=$2
    if awk -f "$check" "$work/$name.s" > "$work/negative.log" 2>&1; then
        printf 'FAIL: JobExec check accepted %s fixture\n' "$name" >&2
        return 1
    fi
    grep -F "$diagnostic" "$work/negative.log"
    printf 'PASS: rejected %s fixture\n' "$name"
}

reject_fixture unrelated 'fork return must be compared to -1 immediately before b.eq'
reject_fixture bypass 'non-error path bypasses ios_execv'
