#!/bin/bash

lipo -remove i386 release/openssl.framework/openssl -o release/openssl.framework/openssl
lipo -remove x86_64 release/openssl.framework/openssl -o release/openssl.framework/openssl

lipo -remove i386 release/libssh2.framework/libssh2 -o release/libssh2.framework/libssh2
lipo -remove x86_64 release/libssh2.framework/libssh2 -o release/libssh2.framework/libssh2

lipo -remove i386 smallRelease/openssl.framework/openssl -o smallRelease/openssl.framework/openssl
lipo -remove x86_64 smallRelease/openssl.framework/openssl -o smallRelease/openssl.framework/openssl

lipo -remove i386 smallRelease/libssh2.framework/libssh2 -o smallRelease/libssh2.framework/libssh2
lipo -remove x86_64 smallRelease/libssh2.framework/libssh2 -o smallRelease/libssh2.framework/libssh2

