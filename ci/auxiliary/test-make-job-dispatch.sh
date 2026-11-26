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
xcrun llvm-objdump --macho --arch=arm64 --no-symbolic-operands --disassemble-symbols=_JobExec \
    "$work/$binary" > "$work/jobexec-addresses.s"
awk -f "$check" "$work/jobexec-addresses.s" "$work/device.s"

# Mutate one instruction in each copy of the real disassembly.
awk -v unrelated="$work/unrelated.s" -v bypass="$work/bypass.s" -v non_redirection="$work/non-redirection.s" '
    !getpid_stub && $2 == "bl" && /symbol stub for: _getpid$/ { getpid_stub = $3 }
    /^_[^[:space:]]+:$/ { in_job = /^_JobExec:$/ }
    {
        original[++n] = $0
        if (!in_job)
            next
        if (!redirection && $2 == "b.eq" && original[n - 1] ~ /cmn[[:space:]]+w0, #0x1$/ &&
            original[n - 2] ~ /bl[[:space:]].*; symbol stub for: _ios_dup2$/)
            redirection = n - 2
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
        if (!compare || !jump || !after_exec || after_exec == -1 || !redirection || !getpid_stub)
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
            row = original[i]
            if (i == redirection)
                sub(/0x[[:xdigit:]]+ ; symbol stub for: _ios_dup2$/, getpid_stub " ; symbol stub for: _getpid", row)
            print row > non_redirection
        }
    }
' "$work/device.s"

reject_fixture() {
    local name=$1 diagnostic=$2
    local status=0
    awk -f "$check" "$work/jobexec-addresses.s" "$work/$name.s" > "$work/negative.log" 2>&1 || status=$?
    if [[ $status != 1 ]]; then
        printf 'FAIL: JobExec check returned %s for %s fixture, expected 1\n' "$status" "$name" >&2
        return 1
    fi
    grep -F "$diagnostic" "$work/negative.log"
    printf 'PASS: rejected %s fixture\n' "$name"
}

reject_fixture unrelated 'fork return must be compared to -1 immediately before b.eq'
reject_fixture bypass 'non-error path bypasses ios_execv'
reject_fixture non-redirection 'non-error path bypasses ios_execv'
