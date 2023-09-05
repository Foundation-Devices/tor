<!--
SPDX-FileCopyrightText: 2022-2023 Foundation Devices Inc.

SPDX-License-Identifier: GPL-3.0-or-later
-->

# tor
[foundation-Devices/tor](https://github.com/Foundation-Devices/tor) is a multi-platform Flutter plugin for managing a Tor proxy.  Based on [arti](https://gitlab.torproject.org/tpo/core/arti).

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

#### macOS

1. Add arch targets:
```sh
rustup target add aarch64-apple-ios aarch64-apple-darwin x86_64-apple-ios x86_64-apple-darwin
```

2. Build macOS arm64 and x86_64 binaries:
```sh
cargo lipo --release --targets aarch64-apple-darwin,x86_64-apple-darwin
```

3. Copy binary file to the macos folder
```sh
cp target/aarch64-apple-darwin/release/libtor_ffi.dylib ../../macos
```
or 
```shell
cp target/aarch64-apple-darwin/release/libtor_ffi.dylib ../../macos
```



## Development

To generate `tor-ffi.h` C bindings for Rust, `cbindgen --config cbindgen.toml --crate tor-ffi --output target/tor-ffi.h` or `cargo build` in `native/tor-ffi` to produce headers according to `build.rs`
To generate `tor_bindings_generated.dart` Dart bindings for C, `flutter pub run ffigen --config ffigen.yaml`

## Example app

`flutter run` in `example` to run the example app

See `example/lib/main.dart` for usage.  Must run the build script for your platform first.
