// SPDX-FileCopyrightText: 2024 Foundation Devices Inc.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import 'package:tor/generated_bindings.dart';
import 'package:tor/tor.dart';

int getNofileLimit() {
  return NativeLibrary(load(Tor.libName)).tor_get_nofile_limit();
}

int setNofileLimit(int limit) {
  return NativeLibrary(load(Tor.libName)).tor_set_nofile_limit(limit);
}
