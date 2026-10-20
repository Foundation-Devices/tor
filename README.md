<!--
SPDX-FileCopyrightText: 2022-2023 Foundation Devices Inc.
SPDX-FileCopyrightText: 2024 Foundation Devices Inc.

SPDX-License-Identifier: MIT
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

[Cargokit](https://github.com/irondash/cargokit) builds and bundles the native Rust library (in `rust/`) for each platform, just `flutter run` it or run it in Android Studio or VS Code (untested).

To update Cargokit in the future, use:
```sh
git subtree pull --prefix cargokit https://github.com/irondash/cargokit.git main --squash
```

## Development

The Dart bindings in `lib/src/rust` are generated from the Rust API in `rust/` by [flutter_rust_bridge](https://github.com/fzyzcjy/flutter_rust_bridge).

Install the codegen tool once, matching the `flutter_rust_bridge` version in `pubspec.yaml`:
```sh
cargo install flutter_rust_bridge_codegen --version 2.11.1
```

Then, after changing the Rust API, regenerate the bindings with:
```sh
flutter_rust_bridge_codegen generate
```

## Example app

`flutter run` in `example` to run the example app

See `example/lib/main.dart` for usage.
