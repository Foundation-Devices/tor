// SPDX-FileCopyrightText: 2026 Foundation Devices Inc.
//
// SPDX-License-Identifier: MIT

import 'dart:async';

/// Serializes Tor lifecycle operations and invalidates stale completions.
class TorLifecycleGate {
  Future<void> _tail = Future.value();
  int _generation = 0;

  int get generation => _generation;

  bool owns(int generation) => generation == _generation;

  void invalidate() {
    _generation++;
  }

  Future<T> run<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }
}
