<!--
SPDX-FileCopyrightText: 2024 Foundation Devices Inc.

SPDX-License-Identifier: MIT
-->

## 0.2.2

* Bound and cancel native Arti bootstrap work, and report unexpected SOCKS
  proxy exits to Dart so consumers can recover without waiting for a failed
  request.

## 0.2.1

* Tear down the Tor client deterministically on `stop()`: await the proxy
  accept loop, cancel accepted connections, and dispose the Rust client
  instead of waiting for Dart GC, which left `tor_cache/dir.lock` held and
  forced a restarted client's directory store into silent read-only mode.

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
