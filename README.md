<!--
SPDX-FileCopyrightText: 2022 Foundation Devices Inc.

SPDX-License-Identifier: GPL-3.0-or-later
-->

# tor

[Foundation-Devices/tor](https://github.com/Foundation-Devices/tor) as a multi-platform Flutter FFI plugin for starting and stopping the Tor daemon. Based on [libtor-sys](https://github.com/MagicalBitcoin/libtor-sys).

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

### Run build scripts

#### Linux

Run build script
```sh
cd scripts/linux
./build_all.sh
```

#### Android

Run the NDK setup and build scripts
```sh
cd scripts/android
./install_ndk.sh
./build_all.sh
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

