#!/bin/bash
# Exercise the real Stock commands in an already launched a-Shell mini Simulator.
# Supply a fixture with payload, password, and phrase files and put its SSH config
# and batch file in Documents/stock-transfer before running. Move the generated
# .out, .err and .recv files out of that directory before rerunning.
# See ssh-stock/README.md.
set -euo pipefail
if [ "$#" -ne 2 ]; then
    echo 'usage: stock-transfer-prompts.sh SIMULATOR-UDID FIXTURE-DIRECTORY' >&2
    exit 64
fi
udid=$1
fixture=$2
app_data=$(xcrun simctl get_app_container "$udid" AsheKube.app.a-Shell-mini data)
dir=$app_data/Documents/stock-transfer
for required in "$dir/config" "$dir/batch" "$fixture/payload" "$fixture/password" "$fixture/phrase"; do
    if [ ! -f "$required" ] || [ ! -r "$required" ]; then
        printf 'stock-transfer-prompts.sh: missing or unreadable input: %s\n' "$required" >&2
        exit 66
    fi
done

send_line() {
    axe type --udid "$udid" "$1" >/dev/null || return
    axe key --udid "$udid" 40 >/dev/null
}

wait_for() {
    local i
    for ((i = 0; i < 160; i++)); do
        if "$@"; then return 0; fi
        sleep .1
    done
    return 1
}

run_row() {
    local row=$1 command=$2 prompt=$3 secret=$4 expected=$5 stderr=$dir/$1.err stdout=$dir/$1.out
    # Require a fresh output directory rather than accepting a stale match.
    if [ -e "$stderr" ] || [ -e "$stdout" ] || [ -e "$dir/$row.recv" ]; then
        printf '%s: stale output\n' "$row"
        return 1
    fi
    send_line "$command > stock-transfer/$row.out 2> stock-transfer/$row.err" || return
    if [ -n "$prompt" ]; then
        if ! wait_for grep -qsF "$prompt" "$stderr"; then
            printf '%s: no secret prompt\n' "$row"
            return 1
        fi
        send_line "$(<"$fixture/$secret")" || return
    fi
    if [ "$expected" = success ]; then
        if ! wait_for cmp -s "$fixture/payload" "$dir/$row.recv"; then
            printf '%s: no matching payload\n' "$row"
            return 1
        fi
    elif ! wait_for grep -qsF 'Permission denied' "$stderr" || [ -e "$dir/$row.recv" ]; then
        printf '%s: noninteractive authentication did not fail as expected\n' "$row"
        return 1
    fi
    if grep -qsF -f "$fixture/password" -f "$fixture/phrase" "$stderr" "$stdout"; then
        printf '%s: secret was echoed\n' "$row"
        return 1
    fi
    if [ -z "$prompt" ] && grep -qsE "[[:alnum:]]'s password:|Enter passphrase for key" "$stderr"; then
        printf '%s: unexpected secret prompt\n' "$row"
        return 1
    fi
    printf '%s: PASS\n' "$row"
}

scp_cmd='scp -F stock-transfer/config'
sftp_cmd='sftp -F stock-transfer/config'
failed=0
run_row scp-password "$scp_cmd stockpw:/fixture/payload stock-transfer/scp-password.recv" "'s password:" password success || failed=1
run_row scp-key "$scp_cmd stockkey:/fixture/payload stock-transfer/scp-key.recv" 'Enter passphrase for key' phrase success || failed=1
run_row sftp-password "$sftp_cmd stockpw:/fixture/payload stock-transfer/sftp-password.recv" "'s password:" password success || failed=1
run_row sftp-key "$sftp_cmd stockkey:/fixture/payload stock-transfer/sftp-key.recv" 'Enter passphrase for key' phrase success || failed=1
run_row scp-control "$scp_cmd stockcontrol:/fixture/payload stock-transfer/scp-control.recv" '' '' success || failed=1
run_row sftp-batch "$sftp_cmd -b stock-transfer/batch stockcontrol" '' '' success || failed=1
run_row scp-noninteractive "$scp_cmd stockpw:/fixture/payload stock-transfer/scp-noninteractive.recv < /dev/null" '' '' denied || failed=1
if [ "$failed" -eq 0 ]; then echo STOCK_TRANSFER_PROMPTS_PASS; fi
exit "$failed"
