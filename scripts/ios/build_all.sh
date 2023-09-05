#!/bin/bash

# Setup
mkdir -p build

# Build versioning
echo ''$(git log -1 --pretty=format:"%H")' '$(date) >> build/git_commit_version.txt
VERSIONS_FILE=../../lib/git_versions.dart
EXAMPLE_VERSIONS_FILE=../../lib/git_versions_example.dart
if [ ! -f "$VERSIONS_FILE" ]; then
    cp $EXAMPLE_VERSIONS_FILE $VERSIONS_FILE
fi
COMMIT=$(git log -1 --pretty=format:"%H")
OS="IOS"
sed -i '' "/\/\*${OS}_VERSION/c\\/\*${OS}_VERSION\*\/ const ${OS}_VERSION = \"$COMMIT\";" $VERSIONS_FILE

# Prepare to build
cp -r ../../rust build/rust
cd build/rust

cd ../../native/tor-ffi

# Install required target if needed
rustup target add aarch64-apple-ios x86_64-apple-ios

# Building using cargo-lipo for iOS
cargo lipo --release

# Moving files to the ios project
#inc=../../../../ios/include
libs=../../../../ios/libs

# Clean old files
rm -rf ${inc} ${libs}
#mkdir ${inc}
mkdir ${libs}

# Copy library
cp target/aarch64-apple-ios/release/libtor_ffi.a ${libs}
