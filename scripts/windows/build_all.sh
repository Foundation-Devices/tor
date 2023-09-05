#!/bin/bash

sudo apt install clang -y

rustup target add x86_64-pc-windows-gnu

mkdir build
echo ''$(git log -1 --pretty=format:"%H")' '$(date) >> build/git_commit_version.txt
VERSIONS_FILE=../../lib/git_versions.dart
EXAMPLE_VERSIONS_FILE=../../lib/git_versions_example.dart
if [ ! -f "$VERSIONS_FILE" ]; then
    cp $EXAMPLE_VERSIONS_FILE $VERSIONS_FILE
fi
COMMIT=$(git log -1 --pretty=format:"%H")
OS="WINDOWS"
sed -i "/\/\*${OS}_VERSION/c\\/\*${OS}_VERSION\*\/ const ${OS}_VERSION = \"$COMMIT\";" $VERSIONS_FILE
cp -r ../../rust build/rust
cd build/rust
if [ "$IS_ARM" = true ]  ; then
    echo "Building arm version"
    cargo build --target aarch64-pc-windows-gnu --release --lib

    mkdir -p target/x86_64-pc-windows-gnu/release
    cp target/aarch64-pc-windows-gnu/release/libtor.so target/x86_64-pc-windows-gnu/release/
else
    echo "Building x86_64 version"
    cargo build --target x86_64-pc-windows-gnu --release --lib
fi

cp target/x86_64-pc-windows-gnu/release/libtor.dll ../libtor.dll
