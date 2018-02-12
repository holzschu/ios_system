#!/bin/bash

IOS_SYSTEM_VER="1.1"
LIBSSH2_VER="1.0"

HHROOT="https://github.com/holzschu"

# "fat" frameworks are only useful for automatic compilation
(cd "${BASH_SOURCE%/*}/Frameworks"
# ios_system
echo "Downloading fat frameworks:"
curl -OL $HHROOT/libssh2-for-iOS/releases/download/v$LIBSSH2_VER/release.tar.gz
( tar -xzf release.tar.gz && rm release.tar.gz ) || { echo "libssh2 failed to download"; exit 1; }
) 



