#!/bin/bash

IOS_SYSTEM_VER="1.0"

HHROOT="https://github.com/holzschu"

(cd "${BASH_SOURCE%/*}/Frameworks"
# ios_system
echo "Downloading ios_system.framework.zip"
curl -OL $HHROOT/ios_system/releases/download/v$IOS_SYSTEM_VER/ios_system.framework.tar.gz
( tar -xzf ios_system.framework.tar.gz && rm ios_system.framework.tar.gz && mv release/* . ) || { echo "ios_system failed to download"; exit 1; }
)




