// SPDX-FileCopyrightText: 2024 Foundation Devices Inc.
//
// SPDX-License-Identifier: MIT

import 'src/rust/api/tor.dart' as rust;

Future<int> getNofileLimit() async {
  final limit = await rust.getNofileLimit();
  return limit.toInt();
}

Future<int> setNofileLimit(int limit) async {
  final result = await rust.setNofileLimit(limit: BigInt.from(limit));
  return result.toInt();
}
