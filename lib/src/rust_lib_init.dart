// SPDX-FileCopyrightText: 2026 Foundation Devices Inc.
//
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

import 'rust/frb_generated.dart';

Future<void> ensureRustLibInit() async {
  if (!RustLib.instance.initialized) {
    // Apple: the Rust staticlib is force-loaded into this plugin's own
    // `tor.framework` (see ios/tor.podspec), so there's no standalone
    // `rust_lib_tor` framework for the default loader to dlopen. Open
    // `tor.framework` by name so symbols resolve within it. Not
    // ExternalLibrary.process(): FRB's unprefixed C symbols collide across
    // multiple FRB crates in one app.
    await RustLib.init(
      externalLibrary: (Platform.isIOS || Platform.isMacOS)
          ? ExternalLibrary.open('tor.framework/tor')
          : null,
    );
  }
}
