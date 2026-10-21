<!--
SPDX-FileCopyrightText: 2024 Foundation Devices Inc.

SPDX-License-Identifier: MIT
-->

## 0.2.2

* Added compatibility with Gradle 9.1 and Android Gradle Plugin 9.0.1.
* Updated the Android build to compile against API 36 with Java 17 and a minimum SDK of 24.
* Pinned `flutter_rust_bridge` to 2.11.1 to match the generated bindings.

## 0.2.1

* Migrated native bindings to `flutter_rust_bridge`.
* Hardened Tor startup, liveness checks, cancellation, and deterministic shutdown.
* Added support for a caller-configurable Tor data directory.
* Fixed iOS initialization, plugin packaging, and `.onion` SOCKS connections.
* Reduced sensitive environment output from Apple builds.

## 0.0.9

* Bumped arti to version 1.4.3

## 0.0.8

* Bumped arti to version 1.2.7

## 0.0.7

* Relicensed to MIT

## 0.0.6

* Pinned 'time' to a specific version

## 0.0.5

* Added rust-toolchain file

## 0.0.4

* Bumped arti to version 1.2.4

## 0.0.3

* Added functions to stop and restart the proxy.

## 0.0.2

* Fixed the Windows build.

## 0.0.1

* Initial release.
