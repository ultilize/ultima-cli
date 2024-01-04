#!/bin/bash

# Define the directory where the build output should go
BUILD_DIR="build"

# Navigate to the root directory of the package
cd "$(dirname "$0")"

# Create the build directory if it doesn't exist
mkdir -p "$BUILD_DIR"

# Build the package
dpkg-deb --build . ultima-cli.deb

# Move the built package to the build directory
mv ultima-cli.deb "$BUILD_DIR/"

echo "Package built and moved to $BUILD_DIR"