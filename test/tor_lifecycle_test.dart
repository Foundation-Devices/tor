// SPDX-FileCopyrightText: 2026 Foundation Devices Inc.
//
// SPDX-License-Identifier: MIT

import 'dart:async';

import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tor/src/rust/api/tor.dart' as rust;
import 'package:tor/tor.dart';

import 'support/tor_test_support.dart';

void main() {
  final native = setUpTorTests();
  final tor = Tor.instance;

  for (final error in <Object>[
    const rust.TorError.runtimeError('partial startup cleanup failed'),
    PanicException('native startup panicked'),
  ]) {
    test('stop reports a superseded startup failure: $error', () async {
      final start = tor.start();
      final startFailed =
          expectLater(start, throwsA(isA<CouldntBootstrapDirectory>()));
      await native.startEntered.future;

      final stop = tor.stop();
      final stopFailed =
          expectLater(stop, throwsA(isA<CouldntBootstrapDirectory>()));
      expect(native.token.cancelled, isTrue);
      native.startResult.completeError(error);

      await startFailed;
      await stopFailed;
      expect(tor.port, -1);
      expect(tor.started, isFalse);
      expect(native.token.isDisposed, isTrue);
    });
  }

  test('stop reports failed cleanup of handles returned by a stale start',
      () async {
    final start = tor.start();
    final startFailed =
        expectLater(start, throwsA(isA<CouldntBootstrapDirectory>()));
    await native.startEntered.future;
    native.stopError = const rust.TorError.proxyStopError('cleanup timed out');

    final stop = tor.stop();
    final stopFailed =
        expectLater(stop, throwsA(isA<CouldntBootstrapDirectory>()));
    native.startResult.complete(native.instance);

    await startFailed;
    await stopFailed;
    expect(native.stops, 1);
    expect(native.instance.isDisposed, isTrue);
    expect(native.instance.client.isDisposed, isTrue);
    expect(native.instance.proxyMonitor.isDisposed, isTrue);
    expect(tor.port, -1);
  });

  test('ordinary startup cancellation stays quiet and permits restart',
      () async {
    final failures = <TorProxyFailure>[];
    final subscription = tor.failures.stream.listen(failures.add);
    addTearDown(subscription.cancel);
    final start = tor.start();
    expect(identical(tor.start(), start), isTrue);
    await native.startEntered.future;
    final generation = tor.routeGeneration;

    final stop = tor.stop();
    expect(tor.routeGeneration, generation + 1);
    native.startResult.completeError(
      const rust.TorError.bootstrapError('Bootstrap was cancelled'),
    );
    await Future.wait([start, stop]);
    expect(tor.starting, isFalse);

    native.reset();
    native.startResult.complete(native.instance);
    await tor.start();
    expect(tor.port, native.instance.socksPort);
    await tor.stop();
    expect(failures, isEmpty);
  });

  test('a stale successful start releases resources without publishing',
      () async {
    final ports = <int>[];
    final subscription = tor.events.stream.listen(ports.add);
    addTearDown(subscription.cancel);
    final start = tor.start();
    await native.startEntered.future;
    final stop = tor.stop();
    native.startResult.complete(native.instance);

    await Future.wait([start, stop]);
    expect(native.stops, 1);
    expect(native.instance.client.isDisposed, isTrue);
    expect(ports, everyElement(-1));
  });

  test('a replacement start waits for the cancelled start and stop', () async {
    final first = tor.start();
    await native.startEntered.future;
    final firstResult = native.startResult;
    final stop = tor.stop();
    native.startResult = Completer();
    native.startEntered = Completer();
    final replacement = tor.start();
    expect(identical(first, replacement), isFalse);
    expect(native.startEntered.isCompleted, isFalse);

    firstResult.completeError(
      const rust.TorError.bootstrapError('Bootstrap was cancelled'),
    );
    await Future.wait([first, stop]);
    await native.startEntered.future;
    native.startResult.complete(native.instance);
    await replacement;
    expect(tor.port, native.instance.socksPort);
  });

  test('stop cancels re-bootstrap before disposing the active client',
      () async {
    native.startResult.complete(native.instance);
    await tor.start();
    final bootstrap = tor.bootstrap();
    await native.bootstrapEntered.future;

    final stop = tor.stop();
    expect(native.token.cancelled, isTrue);
    expect(native.instance.client.isDisposed, isFalse);
    expect(tor.port, -1);
    native.bootstrapResult.completeError(
      const rust.TorError.bootstrapError('Bootstrap was cancelled'),
    );

    await Future.wait([bootstrap, stop]);
    expect(native.instance.client.isDisposed, isTrue);
    expect(tor.bootstrapped, isFalse);
  });

  test('unexpected proxy exit tears down once and emits one failure', () async {
    final failures = <TorProxyFailure>[];
    final subscription = tor.failures.stream.listen(failures.add);
    addTearDown(subscription.cancel);
    final failure = tor.failures.stream.first;
    native.startResult.complete(native.instance);
    native.exit.complete('accept loop failed');

    await tor.start();
    expect((await failure).message, 'accept loop failed');
    expect(tor.port, -1);
    expect(native.stops, 1);
    expect(native.instance.client.isDisposed, isTrue);
    await tor.stop();
    expect(failures, hasLength(1));
  });
}
