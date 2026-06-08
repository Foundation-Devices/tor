// SPDX-FileCopyrightText: 2026 Foundation Devices Inc.
//
// SPDX-License-Identifier: MIT

import 'rust/frb_generated.dart';

Future<void> ensureRustLibInit() async {
  if (!RustLib.instance.initialized) {
    await RustLib.init();
  }
}
