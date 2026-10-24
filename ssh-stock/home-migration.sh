#!/bin/sh
# Verify default config, identity and known_hosts lookup without explicit path options.
set -eu
if [ "$#" -ne 6 ]; then
    echo "Usage: $0 CASE_DIR HOST PORT USER THROWAWAY_IDENTITY KNOWN_HOSTS" >&2
    exit 64
fi
case_dir=$1; host=$2; port=$3; user=$4; identity=$5; known_hosts=$6
mkdir "$case_dir"
mkdir "$case_dir/.ssh"
chmod 700 "$case_dir/.ssh"
cp "$identity" "$case_dir/.ssh/id_ed25519"
chmod 600 "$case_dir/.ssh/id_ed25519"
cp "$known_hosts" "$case_dir/.ssh/known_hosts"
printf 'Host ashell-home-fixture\n HostName %s\n Port %s\n User %s\n StrictHostKeyChecking yes\n IdentitiesOnly yes\n BatchMode yes\n ConnectTimeout 5\n' "$host" "$port" "$user" > "$case_dir/.ssh/config"
SSH_HOME="$case_dir" ssh ashell-home-fixture 'echo ASHELL_SSH_HOME_LOGIN_OK' > "$case_dir/login.txt" 2>&1
grep '^ASHELL_SSH_HOME_LOGIN_OK$' "$case_dir/login.txt"
echo ASHELL_SSH_HOME_MIGRATION_PASS
