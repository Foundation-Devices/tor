// SPDX-FileCopyrightText: 2026 Foundation Devices Inc.
//
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tor/src/rust/api/tor.dart' as rust;
import 'package:tor/src/rust/frb_generated.dart';
import 'package:tor/tor.dart';

FakeTorApi setUpTorTests() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final native = FakeTorApi();
  final tor = Tor.instance;
  late Directory support;

  setUpAll(() {
    RustLib.initMock(api: native);
    support = Directory.systemTemp.createTempSync('tor-lifecycle-test-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => support.path,
    );
  });

  setUp(() async {
    native.reset();
    await Tor.init();
  });

  tearDown(() async {
    native.stopError = null;
    await tor.stop();
    tor.disable();
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await support.delete(recursive: true);
  });

  return native;
}

class _Opaque implements RustOpaqueInterface {
  @override
  bool isDisposed = false;

  @override
  void dispose() => isDisposed = true;
}

class _Client extends _Opaque implements rust.TorClientWrapper {}

class _Proxy extends _Opaque implements rust.TorProxyHandle {}

class _Monitor extends _Opaque implements rust.TorProxyMonitor {}

class FakeTorToken extends _Opaque
    implements rust.TorBootstrapCancellationToken {
  bool cancelled = false;

  @override
  void cancel() => cancelled = true;
}

class FakeTorInstance extends _Opaque implements rust.TorInstance {
  @override
  rust.TorClientWrapper client = _Client();
  @override
  rust.TorProxyHandle proxy = _Proxy();
  @override
  rust.TorProxyMonitor proxyMonitor = _Monitor();
  @override
  int socksPort = 19050;
}

class FakeTorApi implements RustLibApi {
  late Completer<rust.TorInstance> startResult;
  late Completer<void> startEntered;
  late Completer<void> bootstrapResult;
  late Completer<void> bootstrapEntered;
  late Completer<void> dormantResult;
  late Completer<void> dormantEntered;
  late Completer<String?> exit;
  late FakeTorInstance instance;
  late FakeTorToken token;
  Object? stopError;
  int stops = 0;

  void reset() {
    startResult = Completer();
    startEntered = Completer();
    bootstrapResult = Completer();
    bootstrapEntered = Completer();
    dormantResult = Completer();
    dormantEntered = Completer();
    exit = Completer();
    instance = FakeTorInstance();
    stops = 0;
    stopError = null;
  }

  @override
  rust.TorBootstrapCancellationToken
      crateApiTorTorBootstrapCancellationTokenNew() => token = FakeTorToken();

  @override
  Future<rust.TorInstance> crateApiTorStartTor({
    required int socksPort,
    required String stateDir,
    required String cacheDir,
    required rust.TorBootstrapCancellationToken cancellationToken,
  }) {
    expect(socksPort, 0);
    startEntered.complete();
    return startResult.future;
  }

  @override
  Future<void> crateApiTorBootstrap({
    required rust.TorClientWrapper client,
    required rust.TorBootstrapCancellationToken cancellationToken,
  }) {
    bootstrapEntered.complete();
    return bootstrapResult.future;
  }

  @override
  Future<void> crateApiTorSetDormant({
    required rust.TorClientWrapper client,
    required bool softMode,
  }) {
    dormantEntered.complete();
    return dormantResult.future;
  }

  @override
  Future<void> crateApiTorStopProxy(
      {required rust.TorProxyHandle proxy}) async {
    stops++;
    if (!exit.isCompleted) exit.complete(null);
    if (stopError != null) throw stopError!;
  }

  @override
  Future<String?> crateApiTorWaitForProxyExit(
          {required rust.TorProxyMonitor monitor}) =>
      exit.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
