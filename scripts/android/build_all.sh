#!/bin/bash

# setup and cleanup
. ./config.sh
mkdir -p $WORKDIR
mkdir -p $CACHEDIR
# normal to see `cannot remove ... No such file or directory` on first build
rm -r ../../android/src/main/jniLibs/

# # build versioning, TODO fix git_versions.dart & git_versions_example.dart
# # normal to see `cp: cannot stat` and `sed: can't read` until fixed
# echo ''$(git log -1 --pretty=format:"%H")' '$(date) >> build/git_commit_version.txt
# VERSIONS_FILE=../../lib/git_versions.dart
# EXAMPLE_VERSIONS_FILE=../../lib/git_versions_example.dart
# if [ ! -f "$VERSIONS_FILE" ]; then
#     cp $EXAMPLE_VERSIONS_FILE $VERSIONS_FILE
# fi
# COMMIT=$(git log -1 --pretty=format:"%H")
# OS="ANDROID"
# sed -i "/\/\*${OS}_VERSION/c\\/\*${OS}_VERSION\*\/ const ${OS}_VERSION = \"$COMMIT\";" $VERSIONS_FILE

cp -rf ../../native build
cd build/native/tor-ffi

rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android

cargo ndk -t x86_64 -t armeabi-v7a -t arm64-v8a -o ../../../../../android/src/main/jniLibs build
