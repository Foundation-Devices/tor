#!/bin/bash

# setup and cleanup
mkdir -p build

# build versioning, TODO fix git_versions.dart & git_versions_example.dart
# normal to see `cp: cannot stat` and `sed: can't read` until fixed
echo ''$(git log -1 --pretty=format:"%H")' '$(date) >> build/git_commit_version.txt
VERSIONS_FILE=../../lib/git_versions.dart
EXAMPLE_VERSIONS_FILE=../../lib/git_versions_example.dart
if [ ! -f "$VERSIONS_FILE" ]; then
    cp $EXAMPLE_VERSIONS_FILE $VERSIONS_FILE
fi
COMMIT=$(git log -1 --pretty=format:"%H")
OS="LINUX"
sed -i "/\/\*${OS}_VERSION/c\\/\*${OS}_VERSION\*\/ const ${OS}_VERSION = \"$COMMIT\";" $VERSIONS_FILE

rm -rf build/rust
cp -rf ../../native build
cd build/native/tor-ffi

if [ "$IS_ARM" = true ]  ; then
    echo "Building arm version"
    cargo build --target aarch64-unknown-linux-gnu --release --lib

    mkdir -p target/x86_64-unknown-linux-gnu/release
    cp target/aarch64-unknown-linux-gnu/release/libepic_cash_wallet.so target/x86_64-unknown-linux-gnu/release/
else
    echo "Building x86_64 version"
    cargo build --target x86_64-unknown-linux-gnu --release --lib
fi
