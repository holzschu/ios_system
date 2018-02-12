#!/bin/bash

IOS_SYSTEM_VER="1.1"
LIBSSH2_VER="1.0"

HHROOT="https://github.com/holzschu"

(cd "${BASH_SOURCE%/*}/Frameworks"
# ios_system
echo "Downloading fat frameworks:"
curl -OL $HHROOT/libssh2-for-iOS/releases/download/LIBSSH2_VER/release.tar.gz
( tar -xzf release.tar.gz && rm release.tar.gz ) || { echo "libssh2 failed to download"; exit 1; }
)
# If you have issues with "fat" frameworks, use the "thin" ones here:
# (cd "${BASH_SOURCE%/*}/Frameworks"
# # ios_system
# echo "Downloading ios_system.framework.zip"
# curl -OL $HHROOT/ios_system/releases/download/v$IOS_SYSTEM_VER/smallRelease.tar.gz
# ( tar -xzf smallRelease.tar.gz --strip 1 && rm smallRelease.tar.gz ) || { echo "ios_system failed to download"; exit 1; }
# )




