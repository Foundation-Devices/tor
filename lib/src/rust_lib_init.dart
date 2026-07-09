// SPDX-FileCopyrightText: 2026 Foundation Devices Inc.
//
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import 'rust/frb_generated.dart';

Future<void> ensureRustLibInit() async {
  if (!RustLib.instance.initialized) {
    await RustLib.init(
      externalLibrary:
          (Platform.isIOS || Platform.isMacOS) ? _openAppleRustLibrary() : null,
    );
  }
}

ExternalLibrary _openAppleRustLibrary() {
  // SwiftPM links the Rust cdylib as its own binary framework. CocoaPods keeps
  // the Rust staticlib force-loaded into this plugin's `tor.framework`.
  return _openFirstAvailableAppleLibrary([
    'rust_lib_tor.framework/rust_lib_tor',
    'tor.framework/tor',
  ]);
}

ExternalLibrary _openFirstAvailableAppleLibrary(List<String> names) {
  Object? firstError;
  StackTrace? firstStackTrace;

  for (final name in names) {
    try {
      return ExternalLibrary.open(name);
    } catch (error, stackTrace) {
      firstError ??= error;
      firstStackTrace ??= stackTrace;
    }
  }

  Error.throwWithStackTrace(firstError!, firstStackTrace!);
}
