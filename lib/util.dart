// SPDX-FileCopyrightText: 2024 Foundation Devices Inc.
//
// SPDX-License-Identifier: MIT

import 'src/rust/api/tor.dart' as rust;
import 'src/rust_lib_init.dart';

Future<int> getNofileLimit() async {
  await ensureRustLibInit();
  final limit = await rust.getNofileLimit();
  return limit.toInt();
}

Future<int> setNofileLimit(int limit) async {
  await ensureRustLibInit();
  final result = await rust.setNofileLimit(limit: BigInt.from(limit));
  return result.toInt();
}
