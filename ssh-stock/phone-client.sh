#!/bin/sh
# Use a throwaway identity already authorized on the disposable test host.
main() {
    if [ "$#" -ne 6 ]; then
        echo "Usage: $0 CASE_DIRECTORY HOST PORT USER IDENTITY KNOWN_HOSTS" >&2
        return 64
    fi
    case_dir=$1; host=$2; port=$3; user=$4; identity=$5; known_hosts=$6
    case "$case_dir" in /*) ;; *) echo 'CASE_DIRECTORY must be absolute' >&2; return 64 ;; esac
    case "$case_dir" in *[!a-zA-Z0-9_./-]*) echo 'Use a case path without spaces or shell metacharacters' >&2; return 64 ;; esac
    for config_path in "$identity" "$known_hosts"; do
        case "$config_path" in
            ''|*[!a-zA-Z0-9_./~-]*) echo 'Use identity and known_hosts paths without spaces or config metacharacters' >&2; return 64 ;;
        esac
    done
    mkdir "$case_dir" || return 1
    ssh -V > "$case_dir/version.txt" 2>&1 || return 1
    grep 'OpenSSH_10.6p1' "$case_dir/version.txt" || return 1
    ssh-keygen -q -t ed25519 -N '' -f "$case_dir/generated-key" || return 1
    ssh-keygen -y -f "$case_dir/generated-key" > "$case_dir/generated-public-key" || return 1
    grep '^ssh-ed25519 ' "$case_dir/generated-public-key" > /dev/null || return 1
    printf 'Host ashell-ssh-fixture\n HostName %s\n Port %s\n User %s\n IdentityFile %s\n UserKnownHostsFile %s\n StrictHostKeyChecking yes\n IdentitiesOnly yes\n BatchMode yes\n ConnectTimeout 5\n ConnectionAttempts 1\n' "$host" "$port" "$user" "$identity" "$known_hosts" > "$case_dir/config"
    remote_dir=/tmp/ashell-ssh-$(basename "$case_dir")
    ssh -F "$case_dir/config" ashell-ssh-fixture "mkdir '$remote_dir' && echo ASHELL_SSH_LOGIN_OK" > "$case_dir/login.txt" 2>&1 || return 1
    grep '^ASHELL_SSH_LOGIN_OK$' "$case_dir/login.txt" || return 1
    printf 'ASHELL_SSH round trip\n' > "$case_dir/input"
    scp -F "$case_dir/config" "$case_dir/input" "ashell-ssh-fixture:$remote_dir/scp" > "$case_dir/scp.txt" 2>&1 || return 1
    scp -F "$case_dir/config" "ashell-ssh-fixture:$remote_dir/scp" "$case_dir/scp-back" >> "$case_dir/scp.txt" 2>&1 || return 1
    diff -q "$case_dir/input" "$case_dir/scp-back" || return 1
    printf 'put %s %s\nget %s %s\n' "$case_dir/input" "$remote_dir/sftp" "$remote_dir/sftp" "$case_dir/sftp-back" > "$case_dir/sftp.batch"
    sftp -F "$case_dir/config" -b "$case_dir/sftp.batch" ashell-ssh-fixture > "$case_dir/sftp.txt" 2>&1 || return 1
    diff -q "$case_dir/input" "$case_dir/sftp-back" || return 1
    mkdir "$case_dir/multi" || return 1
    scp -F "$case_dir/config" "ashell-ssh-fixture:$remote_dir/scp" "ashell-ssh-fixture:$remote_dir/sftp" "$case_dir/multi/" > "$case_dir/scp-multi.txt" 2>&1 || return 1
    diff -q "$case_dir/input" "$case_dir/multi/scp" || return 1
    diff -q "$case_dir/input" "$case_dir/multi/sftp" || return 1
    mkdir "$case_dir/multi-missing" || return 1
    scp -F "$case_dir/config" "ashell-ssh-fixture:$remote_dir/missing" "ashell-ssh-fixture:$remote_dir/scp" "$case_dir/multi-missing/" > "$case_dir/scp-missing.txt" 2>&1
    scp_status=$?
    [ "$scp_status" -ne 0 ] || return 1
    diff -q "$case_dir/input" "$case_dir/multi-missing/scp" || return 1
    ssh -F "$case_dir/config" ashell-ssh-fixture 'echo ASHELL_SSH_RECOVERED' > "$case_dir/recovered.txt" 2>&1 || return 1
    grep '^ASHELL_SSH_RECOVERED$' "$case_dir/recovered.txt" || return 1
    echo ASHELL_SSH_CLIENT_PASS
}
main "$@"
