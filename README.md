<!--
SPDX-FileCopyrightText: 2022-2023 Foundation Devices Inc.

SPDX-License-Identifier: GPL-3.0-or-later
-->

# tor

[foundation-Devices/tor](https://github.com/Foundation-Devices/tor) is a multi-platform Flutter plugin for managing a Tor proxy.  Based on [arti](https://gitlab.torproject.org/tpo/core/arti).

## Getting started

### [Install rust](https://www.rust-lang.org/tools/install)

Use `rustup`, not `homebrew`.

### Install cargo ndk

```sh
cargo install cargo-ndk
```

### Cargokit

[Cargokit](https://github.com/irondash/cargokit) handles building, just `flutter run` it or run it in Android Studio or VS Code (untested).

To update Cargokit in the future, use:
```sh
git subtree pull --prefix cargokit https://github.com/irondash/cargokit.git main --squash
```

## Development

To generate `tor-ffi.h` C bindings for Rust, `cbindgen --config cbindgen.toml --crate tor-ffi --output target/tor-ffi.h` or `cargo build` in `native/tor-ffi` to produce headers according to `build.rs`
To generate `tor_bindings_generated.dart` Dart bindings for C, `flutter pub run ffigen --config ffigen.yaml`

## Example app

`flutter run` in `example` to run the example app

See `example/lib/main.dart` for usage.  Must run the build script for your platform first.
