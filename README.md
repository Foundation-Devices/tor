<!--
SPDX-FileCopyrightText: 2022-2023 Foundation Devices Inc.

SPDX-License-Identifier: GPL-3.0-or-later
-->

# Tor
A multi-platform Flutter plugin for starting and stopping the Tor daemon.  Based on [arti](https://gitlab.torproject.org/tpo/core/arti).

## Getting started

### [Install rust](https://www.rust-lang.org/tools/install)

### Install cargo ndk
```sh
cargo install cargo-ndk
```

### Install dependencies
```sh
sudo apt install git build-essential cmake llvm clang pkg-config cargo rustc libssl-dev libc6-dev-i386
```

### Build plugin

#### Linux

1. Navigate to the `native/tor-ffi` directory in your project:
   ```sh
   cd native/tor-ffi
   ```

2. Remove any previous build targets (it's normal to see an error message if it's your first build):
   ```sh
   rm -rf target
   ```
   
3. Add Rust targets for Linux:
  ```sh
  rustup target add x86_64-unknown-linux-gnu
  ```

4. Build the project for Linux:
  ```sh
  cargo build --target x86_64-unknown-linux-gnu --release --lib
  ```

#### Android

1. Download and unzip Android NDK:
```sh
curl "https://dl.google.com/android/repository/android-ndk-${ANDROID_NDK_TAG}-linux-x86_64.zip" -o ${ANDROID_NDK_ZIP}
unzip $ANDROID_NDK_ZIP
```

2. Navigate to the `native/tor-ffi` directory:
```sh
cd native/tor-ffi
```

3. Remove any previous build targets (it's normal to see an error message if it's your first build):
   ```sh
   rm -rf target
   ```

4. Add Rust targets for Android architectures:
```sh
rustup target add aarch64-linux-android armv7-linux-androideabi i686-linux-android x86_64-linux-android
```

5. Build the project for Android architectures:
```sh
cargo ndk -t x86_64 -t armeabi-v7a -t arm64-v8a -o ../../../../../android/src/main/jniLibs build
```

## Development

To generate `tor-ffi.h` C bindings for Rust, `cbindgen --config cbindgen.toml --crate tor-ffi --output target/tor-ffi.h` or `cargo build` in `native/tor-ffi` to produce headers according to `build.rs`
To generate `tor_bindings_generated.dart` Dart bindings for C, `flutter pub run ffigen --config ffigen.yaml`

## Example app

`flutter run` in `example` to run the example app

See `example/lib/main.dart` for usage.  Must run the build script for your platform first.

# Flutter FFI plugin template

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
    * See the documentation in ios/tor.podspec.
    * See the documentation in macos/tor.podspec.
* For Linux and Windows: CMake.
    * See the documentation in linux/CMakeLists.txt.
    * See the documentation in windows/CMakeLists.txt.

## Binding to native code

To use the native code, bindings in Dart are needed.
To avoid writing these by hand, they are generated from the header file
(`src/tor.h`) by `package:ffigen`.
Regenerate the bindings by running `flutter pub run ffigen --config ffigen.yaml`.

## Flutter help

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
