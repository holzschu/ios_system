#!/bin/bash

IOS_SYSTEM_VER="2.4"

HHROOT="https://github.com/holzschu"

(cd "${BASH_SOURCE%/*}/Frameworks"
# ios_system: the basis, with ~20 libraries
echo "Downloading ios_system.framework and associated frameworks"
curl -OL $HHROOT/ios_system/releases/download/v$IOS_SYSTEM_VER/release.tar.gz
( tar -xzf release.tar.gz --strip 1 && rm release.tar.gz ) || { echo "ios_system failed to download"; exit 1; }
)
