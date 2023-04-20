<!--
SPDX-FileCopyrightText: 2022 Foundation Devices Inc.

SPDX-License-Identifier: GPL-3.0-or-later
-->

# flutter_libtor

[Foundation-Devices/tor](https://github.com/Foundation-Devices/tor) as a multi-platform Flutter FFI plugin for starting and stopping the Tor daemon. Based on [libtor-sys](https://github.com/MagicalBitcoin/libtor-sys).

## Getting started

### [Install rust](https://www.rust-lang.org/tools/install)

### Install cargo ndk
```sh
cargo install cargo-ndk
```

### Add platform-specific targets and run build scripts 

#### Android

Add targets to rust and install dependencies (see https://github.com/EpicCash/epic/blob/master/doc/build.md#requirements) 
```sh
rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android

sudo apt-get install libc6-dev-i386

https://github.com/EpicCash/epic/blob/master/doc/build.md#requirements
sudo apt install build-essential cmake git libgit2-dev clang libncurses5-dev libncursesw5-dev zlib1g-dev pkg-config llvm
sudo apt-get install build-essential debhelper cmake libclang-dev libncurses5-dev clang libncursesw5-dev cargo rustc opencl-headers libssl-dev pkg-config ocl-icd-opencl-dev
```

Run the NDK setup and build scripts
```sh
cd scripts/android
./install_ndk.sh
./build_all.sh
```

#### iOS

```sh
rustup target add aarch64-apple-ios x86_64-apple-ios aarch64-apple-ios-sim

cargo install cargo-lipo
cargo install cbindgen

cd scripts/ios
./build_all.sh
```

## Flutter FFI plugin template

This project is a starting point for a Flutter
[FFI plugin](https://docs.flutter.dev/development/platform-integration/c-interop),
a specialized package that includes native code directly invoked with Dart FFI.

## Project stucture

This template uses the following structure:

* `src`: Contains the native source code, and a CmakeFile.txt file for building
  that source code into a dynamic library.

* `lib`: Contains the Dart code that defines the API of the plugin, and which
  calls into the native code using `dart:ffi`.

* platform folders (`android`, `ios`, `windows`, etc.): Contains the build files
  for building and bundling the native code library with the platform application.

## Buidling and bundling native code

The `pubspec.yaml` specifies FFI plugins as follows:

```yaml
  plugin:
    platforms:
      some_platform:
        ffiPlugin: true
```

This configuration invokes the native build for the various target platforms
and bundles the binaries in Flutter applications using these FFI plugins.

This can be combined with dartPluginClass, such as when FFI is used for the
implementation of one platform in a federated plugin:

```yaml
  plugin:
    implements: some_other_plugin
    platforms:
      some_platform:
        dartPluginClass: SomeClass
        ffiPlugin: true
```

A plugin can have both FFI and method channels:

```yaml
  plugin:
    platforms:
      some_platform:
        pluginClass: SomeName
        ffiPlugin: true
```

The native build systems that are invoked by FFI (and method channel) plugins are:

* For Android: Gradle, which invokes the Android NDK for native builds.
  * See the documentation in android/build.gradle.
* For iOS and MacOS: Xcode, via CocoaPods.
  * See the documentation in ios/flutter_libtor.podspec.
  * See the documentation in macos/flutter_libtor.podspec.
* For Linux and Windows: CMake.
  * See the documentation in linux/CMakeLists.txt.
  * See the documentation in windows/CMakeLists.txt.

## Binding to native code

To use the native code, bindings in Dart are needed.
To avoid writing these by hand, they are generated from the header file
(`src/flutter_libtor.h`) by `package:ffigen`.
Regenerate the bindings by running `flutter pub run ffigen --config ffigen.yaml`.

## Invoking native code

Very short-running native functions can be directly invoked from any isolate.
For example, see `sum` in `lib/flutter_libtor.dart`.

Longer-running functions should be invoked on a helper isolate to avoid
dropping frames in Flutter applications.
For example, see `sumAsync` in `lib/flutter_libtor.dart`.

## Flutter help

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

