#!/bin/bash
set -ex

# Do nothing for installhdrs
[ "$ACTION" == "installhdrs" ] && exit 0

# Make -lcurl work.
mkdir -p "${INSTALL_DIR}"
ln -s -f "${FULL_PRODUCT_NAME/dylib/tbd}" "$INSTALL_DIR"/libcurl.tbd

[ "$ACTION" == "installapi" ] && exit 0

# Make -lcurl work.
ln -s -f "$FULL_PRODUCT_NAME" "$INSTALL_DIR"/libcurl.dylib

# Legacy compatibility.
if [ "$PLATFORM_NAME" = "macosx" ]; then
	ln -s -f "$FULL_PRODUCT_NAME" "$INSTALL_DIR"/libcurl.3.dylib
fi
