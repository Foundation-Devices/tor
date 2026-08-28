// SPDX-FileCopyrightText: 2026 Foundation Devices Inc.
//
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tor/src/tor_lifecycle_gate.dart';

void main() {
  test('serializes lifecycle operations after failures', () async {
    final gate = TorLifecycleGate();
    final firstStarted = Completer<void>();
    final releaseFirst = Completer<void>();
    final order = <String>[];

    final first = gate.run(() async {
      order.add('start');
      firstStarted.complete();
      await releaseFirst.future;
      throw StateError('failed start');
    });
    await firstStarted.future;

    final second = gate.run(() async {
      order.add('stop');
    });
    expect(order, ['start']);

    releaseFirst.complete();
    await expectLater(first, throwsStateError);
    await second;
    expect(order, ['start', 'stop']);
  });

  test('invalidation prevents an in-flight start from publishing', () async {
    final gate = TorLifecycleGate();
    final generation = gate.generation;
    final startEntered = Completer<void>();
    final releaseStart = Completer<void>();
    var published = false;

    final start = gate.run(() async {
      startEntered.complete();
      await releaseStart.future;
      if (gate.owns(generation)) {
        published = true;
      }
    });
    await startEntered.future;

    gate.invalidate();
    final stop = gate.run(() async {});
    releaseStart.complete();

    await start;
    await stop;
    expect(published, isFalse);
  });
}
