#!/bin/bash

LIBSSH2_VER="1.8.0"
IOS_SYSTEM_VER="1.0"

HHROOT="https://github.com/holzschu"

(cd "${BASH_SOURCE%/*}/Frameworks"
# libssh2 + openssl:
echo "Downloading libssh2-$LIBSSH2_VER.framework.tar.gz"
curl -OL $HHROOT/libssh2-for-iOS/releases/download/v1.0/release.tar.gz
( tar -zxf release.tar.gz && rm release.tar.gz ) || { echo "Libssh2 framework failed to download"; exit 1; }
)



