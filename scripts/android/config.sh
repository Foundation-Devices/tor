#!/bin/bash

export WORKDIR="$(pwd)/"build
export CACHEDIR="$(pwd)/"cache

export ANDROID_NDK_ZIP=${CACHEDIR}/android-ndk-r20b.zip
export ANDROID_NDK_ROOT=${WORKDIR}/android-ndk-r20b
export ANDROID_NDK_HOME=$ANDROID_NDK_ROOT

export API=21
#r21e also works and was the preferred before
