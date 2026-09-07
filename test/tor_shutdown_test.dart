// SPDX-FileCopyrightText: 2026 Foundation Devices Inc.
//
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:tor/src/rust/api/tor.dart' as rust;
import 'package:tor/tor.dart';

import 'support/tor_test_support.dart';

void main() {
  final native = setUpTorTests();
  final tor = Tor.instance;

  test('overlapping stops both report failed teardown', () async {
    native.startResult.complete(native.instance);
    await tor.start();
    native.stopError = const rust.TorError.proxyStopError('cleanup timed out');

    final first = tor.stop();
    final second = tor.stop();
    await Future.wait([
      expectLater(first, throwsA(isA<rust.TorError>())),
      expectLater(second, throwsA(isA<rust.TorError>())),
    ]);
    expect(native.stops, 1);
  });

  test('stop waits for an active dormant call before disposing the client',
      () async {
    native.startResult.complete(native.instance);
    await tor.start();
    final dormant = tor.setClientDormant(true);
    await native.dormantEntered.future;

    final stop = tor.stop();
    await Future<void>.delayed(Duration.zero);
    final stopsWhileDormantPending = native.stops;
    final disposedWhileDormantPending = native.instance.client.isDisposed;
    native.dormantResult.complete();
    await Future.wait([dormant, stop]);

    expect(stopsWhileDormantPending, 0);
    expect(disposedWhileDormantPending, isFalse);
    expect(native.instance.client.isDisposed, isTrue);
    expect(native.stops, 1);
  });

  test('stop skips a queued dormant call from the previous generation',
      () async {
    native.startResult.complete(native.instance);
    await tor.start();
    native.dormantResult.complete();

    final dormant = tor.setClientDormant(true);
    final stop = tor.stop();
    await Future.wait([dormant, stop]);

    expect(native.dormantEntered.isCompleted, isFalse);
  });

  test('a second stop invalidates a replacement queued after the first stop',
      () async {
    native.startResult.complete(native.instance);
    await tor.start();
    final firstStop = tor.stop();
    native.startEntered = Completer();
    native.startResult = Completer()..complete(FakeTorInstance());
    final replacement = tor.start();
    final secondStop = tor.stop();

    await Future.wait([firstStop, replacement, secondStop]);

    expect(native.startEntered.isCompleted, isFalse);
    expect(tor.started, isFalse);
    expect(tor.port, -1);
    expect(native.stops, 1);
  });
}
