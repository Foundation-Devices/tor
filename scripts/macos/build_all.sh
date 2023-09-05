#!/bin/bash

# Build versioning
echo ''$(git log -1 --pretty=format:"%H")' '$(date) >> build/git_commit_version.txt
VERSIONS_FILE=../../lib/git_versions.dart
EXAMPLE_VERSIONS_FILE=../../lib/git_versions_example.dart
if [ ! -f "$VERSIONS_FILE" ]; then
    cp $EXAMPLE_VERSIONS_FILE $VERSIONS_FILE
fi
COMMIT=$(git log -1 --pretty=format:"%H")
OSX="OSX"
sed -i '' "/\/\*${OS}_VERSION/c\\/\*${OS}_VERSION\*\/ const ${OS}_VERSION = \"$COMMIT\";" $VERSIONS_FILE
cp -r ../../rust build/rust
cd build/rust

# Change directory to your native Rust code
cd ../../native/tor-ffi

# Building
cargo build --target x86_64-apple-darwin --release --lib

# Copy the built library to macOS location
mkdir -p ../../macos/libs
cp target/x86_64-apple-darwin/release/libtor_ffi.dylib ../../macos/libs
