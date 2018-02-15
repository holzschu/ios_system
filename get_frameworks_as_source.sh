#!/bin/bash

IOS_SYSTEM_VER="1.1"
LIBSSH2_VER="1.0"

HHROOT="https://github.com/holzschu"

echo "Cloning the repository:"
git clone $HHROOT/libssh2-for-iOS --recursive
echo "Building:"
(cd libssh2-for-iOS
sh ./build-all.sh openssl
cp -r build/Debug-iphoneos/libssh2.framework ../Frameworks/
cp -r build/Debug-iphoneos/openssl.framework ../Frameworks/
)

