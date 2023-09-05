#!/bin/bash

export WORKDIR="$(pwd)/"build
export CACHEDIR="$(pwd)/"cache

export ANDROID_NDK_ZIP=${CACHEDIR}/android-ndk-r20b.zip
export ANDROID_NDK_ROOT=${WORKDIR}/android-ndk-r20b
export ANDROID_NDK_HOME=$ANDROID_NDK_ROOT

export API=21
#r21e also works and was the preferred before

ARCH=linux-x86_64
export TOOLCHAIN=$ANDROID_NDK_HOME/toolchains/llvm/prebuilt/$ARCH
export AR=$TOOLCHAIN/bin/llvm-ar
export CC=$TOOLCHAIN/bin/$TARGET$API-clang
export AS=$CC
export CXX=$TOOLCHAIN/bin/$TARGET$API-clang++
export LD=$TOOLCHAIN/bin/ld
export RANLIB=$TOOLCHAIN/bin/x86_64-linux-android-ranlib # TODO change based on arch
export STRIP=$TOOLCHAIN/bin/llvm-strip
