#!/bin/bash
# Build Conky Manager .deb package

set -e

PACKAGE_NAME="conky-manager"
VERSION="2.1.2"
ARCH="all"
BUILD_DIR="deb"

echo "Building $PACKAGE_NAME $VERSION..."

# Update version in control file
sed -i "s/Version: .*/Version: $VERSION/" "$BUILD_DIR/DEBIAN/control"

# Ensure postinst is executable
chmod +x "$BUILD_DIR/DEBIAN/postinst"

# Build the package
dpkg-deb --build "$BUILD_DIR" "${PACKAGE_NAME}_${ARCH}.deb"

echo ""
echo "Package built: ${PACKAGE_NAME}_${ARCH}.deb"
echo ""
echo "Install with: sudo dpkg -i ${PACKAGE_NAME}_${ARCH}.deb"
echo "Or: sudo apt install ./${PACKAGE_NAME}_${ARCH}.deb"
