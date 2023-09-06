#!/bin/bash

# setup and cleanup
. ./config.sh
mkdir -p $WORKDIR
mkdir -p $CACHEDIR

ANDROID_NDK_SHA256="8381c440fe61fcbb01e209211ac01b519cd6adf51ab1c2281d5daad6ca4c8c8c"
ANDROID_NDK_TAG="r20b"
ANDROID_NDK_ZIP=${CACHEDIR}/android-ndk-${ANDROID_NDK_TAG}.zip

if [ ! -e "$ANDROID_NDK_ZIP" ]; then
  curl "https://dl.google.com/android/repository/android-ndk-${ANDROID_NDK_TAG}-linux-x86_64.zip" -o ${ANDROID_NDK_ZIP}
fi
# check hash
echo $ANDROID_NDK_SHA256 $ANDROID_NDK_ZIP | sha256sum -c || exit 1
unzip $ANDROID_NDK_ZIP -d $WORKDIR
