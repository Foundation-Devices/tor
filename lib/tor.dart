// SPDX-FileCopyrightText: 2022 Foundation Devices Inc.
// SPDX-FileCopyrightText: 2024 Foundation Devices Inc.
//
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:path_provider/path_provider.dart';

import 'src/rust/api/tor.dart' as rust;
import 'src/rust_lib_init.dart';
import 'src/tor_lifecycle_gate.dart';

export 'src/rust/api/tor.dart' show TorError;

class CouldntBootstrapDirectory implements Exception {
  String? rustError;

  CouldntBootstrapDirectory({this.rustError});

  @override
  String toString() => 'CouldntBootstrapDirectory: $rustError';
}

class NotSupportedPlatform implements Exception {
  final String platform;
  NotSupportedPlatform(this.platform);

  @override
  String toString() => 'NotSupportedPlatform: $platform';
}

class ClientNotActive implements Exception {
  @override
  String toString() => 'ClientNotActive: Tor client is not active';
}

class TorProxyFailure {
  final String message;

  TorProxyFailure(this.message);

  @override
  String toString() => 'TorProxyFailure: $message';
}

class Tor {
  rust.TorClientWrapper? _client;
  rust.TorProxyHandle? _proxy;

  /// Flag to indicate that Tor client and proxy have started. Traffic is routed through the proxy only if it is also [enabled].
  bool get started => _started;

  /// Getter for the started flag.
  bool _started = false;

  /// True while the client is starting or re-bootstrapping.
  bool get starting => _startInFlight != null || _bootstrapInFlight != null;

  Future<void>? _startInFlight;
  int? _startGeneration;
  Future<void>? _bootstrapInFlight;
  int? _bootstrapGeneration;
  Future<void>? _stopInFlight;
  rust.TorBootstrapCancellationToken? _bootstrapCancellationToken;
  final TorLifecycleGate _lifecycle = TorLifecycleGate();

  /// Changes whenever the published Tor route is invalidated.
  int get routeGeneration => _lifecycle.generation;

  /// Flag to indicate that traffic should flow through the proxy.
  bool _enabled = false;

  /// Getter for the enabled flag.
  bool get enabled => _enabled;

  /// Flag to indicate that a Tor circuit is thought to have been established
  /// (true means that Tor has bootstrapped).
  bool get bootstrapped => _bootstrapped;

  /// Getter for the bootstrapped flag.
  bool _bootstrapped = false;

  /// A stream of Tor events.
  ///
  /// This stream broadcast just the port for now (-1 if circuit not established or proxy not enabled)
  final StreamController<int> events = StreamController<int>.broadcast();

  /// Reports an unexpected loss of the published SOCKS proxy.
  final StreamController<TorProxyFailure> failures =
      StreamController<TorProxyFailure>.broadcast();

  /// Getter for the proxy port.
  ///
  /// Returns -1 if Tor is not enabled or if the circuit is not established.
  ///
  /// Returns the proxy port if Tor is enabled and the circuit is established.
  ///
  /// This is the port that should be used for all requests.
  int get port {
    if (!_enabled || !_started || !_bootstrapped) {
      return -1;
    }
    return _proxyPort;
  }

  /// The proxy port.
  int _proxyPort = -1;

  /// Singleton instance of the Tor class.
  static final Tor _instance = Tor._internal();

  /// Getter for the singleton instance of the Tor class.
  static Tor get instance => _instance;

  /// Initialize the Tor ffi lib instance if it hasn't already been set. Nothing
  /// changes if _tor is already been set.
  ///
  /// Returns a Future that completes when the Tor service has started.
  ///
  /// Throws an exception if the Tor service fails to start.
  static Future<Tor> init({bool enabled = true}) async {
    var singleton = Tor._instance;
    singleton._enabled = enabled;
    await ensureRustLibInit();
    return singleton;
  }

  /// Private constructor for the Tor class.
  Tor._internal() {
    if (kDebugMode) {
      print("Instance of Tor created!");
    }
  }

  /// Start the Tor service.
  Future<void> enable() async {
    _enabled = true;
    if (!started) {
      await start();
    }
    broadcastState();
  }

  void broadcastState() {
    events.add(port);
  }

  /// Start the Tor service.
  ///
  /// This will start the Tor service and establish a Tor circuit.
  ///
  /// Throws an exception if the Tor service fails to start.
  ///
  /// Returns a Future that completes when the Tor service has started.
  Future<void> start() {
    if (_started) {
      return _bootstrapped ? Future.value() : bootstrap();
    }

    final generation = _lifecycle.generation;
    final inFlight = _startInFlight;
    if (inFlight != null && _startGeneration == generation) return inFlight;

    late final Future<void> start;
    start = _lifecycle.run(() => _startInternal(generation)).whenComplete(() {
      if (identical(_startInFlight, start)) {
        _startInFlight = null;
        _startGeneration = null;
      }
    });
    _startInFlight = start;
    _startGeneration = generation;
    return start;
  }

  Future<void> _startInternal(int generation) async {
    if (!_lifecycle.owns(generation)) return;

    broadcastState();

    await ensureRustLibInit();

    // Set the state and cache directories.
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final stateDir = await Directory(
      '${appSupportDir.path}/tor_state',
    ).create();
    final cacheDir = await Directory(
      '${appSupportDir.path}/tor_cache',
    ).create();

    if (!_lifecycle.owns(generation)) return;

    try {
      final cancellationToken = rust.TorBootstrapCancellationToken();
      _bootstrapCancellationToken = cancellationToken;

      // Start Tor - this is a blocking operation
      late final rust.TorInstance torInstance;
      try {
        torInstance = await rust.startTor(
          // Let the final native listener select and retain the ephemeral port.
          socksPort: 0,
          stateDir: stateDir.path,
          cacheDir: cacheDir.path,
          cancellationToken: cancellationToken,
        );
      } finally {
        if (identical(_bootstrapCancellationToken, cancellationToken)) {
          _bootstrapCancellationToken = null;
        }
        cancellationToken.dispose();
      }

      late final rust.TorClientWrapper client;
      late final rust.TorProxyHandle proxy;
      late final rust.TorProxyMonitor proxyMonitor;
      late final int proxyPort;
      try {
        client = torInstance.client;
        proxy = torInstance.proxy;
        proxyMonitor = torInstance.proxyMonitor;
        proxyPort = torInstance.socksPort;
      } finally {
        // The getters above clone; free the container now instead of at GC so
        // it cannot keep an extra client reference (and dir.lock) alive.
        torInstance.dispose();
      }

      if (!_lifecycle.owns(generation)) {
        proxyMonitor.dispose();
        await _stopResources(proxy, client);
        return;
      }

      _client = client;
      _proxy = proxy;
      _proxyPort = proxyPort;
      _started = true;
      _bootstrapped = true; // startTor creates a bootstrapped client

      broadcastState();
      unawaited(_monitorProxy(proxy, proxyMonitor, generation));
    } on rust.TorError catch (e) {
      // Native cleanup failures are RuntimeError/ProxyStopError, not a normal
      // bootstrap cancellation. Keep those observable even after stop().
      if (!_lifecycle.owns(generation) && e is rust.TorError_BootstrapError) {
        return;
      }
      throw CouldntBootstrapDirectory(rustError: e.toString());
    } on PanicException catch (e) {
      // FRB converts Rust panics to PanicException - this is the key benefit!
      throw CouldntBootstrapDirectory(rustError: 'Rust panic: ${e.message}');
    }
  }

  /// Bootstrap the Tor service.
  ///
  /// This will bootstrap the Tor service and establish a Tor circuit.  This
  /// function should only be called after the Tor service has been started.
  ///
  /// This function will block until the Tor service has bootstrapped.
  ///
  /// Throws an exception if the Tor service fails to bootstrap.
  ///
  /// Returns void.
  Future<void> bootstrap() {
    final generation = _lifecycle.generation;
    final inFlight = _bootstrapInFlight;
    if (inFlight != null && _bootstrapGeneration == generation) {
      return inFlight;
    }

    late final Future<void> bootstrap;
    bootstrap =
        _lifecycle.run(() => _bootstrapInternal(generation)).whenComplete(() {
      if (identical(_bootstrapInFlight, bootstrap)) {
        _bootstrapInFlight = null;
        _bootstrapGeneration = null;
      }
    });
    _bootstrapInFlight = bootstrap;
    _bootstrapGeneration = generation;
    return bootstrap;
  }

  Future<void> _bootstrapInternal(int generation) async {
    if (!_lifecycle.owns(generation)) return;

    final client = _client;
    if (client == null) {
      throw ClientNotActive();
    }

    try {
      final cancellationToken = rust.TorBootstrapCancellationToken();
      _bootstrapCancellationToken = cancellationToken;
      try {
        await rust.bootstrap(
          client: client,
          cancellationToken: cancellationToken,
        );
      } finally {
        if (identical(_bootstrapCancellationToken, cancellationToken)) {
          _bootstrapCancellationToken = null;
        }
        cancellationToken.dispose();
      }
      if (!_lifecycle.owns(generation) || !identical(_client, client)) return;
      _bootstrapped = true;
      broadcastState();
    } on rust.TorError catch (e) {
      if (!_lifecycle.owns(generation) || !identical(_client, client)) return;
      _bootstrapped = false;
      broadcastState();
      throw CouldntBootstrapDirectory(rustError: e.toString());
    }
  }

  /// Prevent traffic flowing through the proxy
  void disable() {
    _enabled = false;
    broadcastState();
  }

  /// Stops the proxy
  Future<void> stop() {
    final proxy = _proxy;
    final client = _client;
    final previousStop = _stopInFlight;

    // Invalidate a start or bootstrap before it can publish stale state. The
    // queued stop then waits for that operation to release its native handles.
    _lifecycle.invalidate();
    _bootstrapCancellationToken?.cancel();

    // Stop publishing the route before awaiting native shutdown so callers
    // cannot start new work against a proxy that is being torn down.
    _proxy = null;
    _client = null;
    _proxyPort = -1;
    _started = false;
    _bootstrapped = false;
    broadcastState();

    // The queue continues after errors, so also observe the operations whose
    // unpublished resources it is waiting to release. Wait for cleanup even
    // when an operation fails before reporting the error to the stop caller.
    late final Future<void> stop;
    stop = Future.wait<void>([
      if (previousStop != null) previousStop,
      if (_startInFlight != null) _startInFlight!,
      if (_bootstrapInFlight != null) _bootstrapInFlight!,
      _lifecycle.run(() => _stopResources(proxy, client)),
    ]).then((_) {}).whenComplete(() {
      if (identical(_stopInFlight, stop)) {
        _stopInFlight = null;
      }
    });
    _stopInFlight = stop;
    return stop;
  }

  Future<void> _monitorProxy(
    rust.TorProxyHandle proxy,
    rust.TorProxyMonitor monitor,
    int generation,
  ) async {
    try {
      final message = await rust.waitForProxyExit(monitor: monitor);
      if (message == null ||
          !_lifecycle.owns(generation) ||
          !identical(_proxy, proxy)) {
        return;
      }
      await _handleProxyFailure(proxy, generation, message);
    } catch (error) {
      await _handleProxyFailure(proxy, generation, error.toString());
    }
  }

  Future<void> _handleProxyFailure(
    rust.TorProxyHandle proxy,
    int generation,
    String message,
  ) async {
    if (!_lifecycle.owns(generation) || !identical(_proxy, proxy)) return;

    try {
      await stop();
    } catch (error) {
      message = '$message; teardown failed: $error';
    } finally {
      failures.add(TorProxyFailure(message));
    }
  }

  Future<void> _stopResources(
    rust.TorProxyHandle? proxy,
    rust.TorClientWrapper? client,
  ) async {
    try {
      if (proxy != null) {
        await rust.stopProxy(proxy: proxy);
      }
    } finally {
      // Drop the Rust client now instead of at GC: a lingering client holds
      // tor_cache/dir.lock, forcing a restarted client's dirmgr into read-only.
      client?.dispose();
    }
  }

  Future<void> setClientDormant(bool dormant) {
    final generation = _lifecycle.generation;
    return _lifecycle.run(() async {
      if (!_lifecycle.owns(generation)) return;

      final client = _client;
      if (client == null || !started || !bootstrapped) {
        throw ClientNotActive();
      }

      await rust.setDormant(client: client, softMode: dormant);
    });
  }

  Future<void> isReady() async {
    return await Future.doWhile(
      () => Future.delayed(const Duration(seconds: 1)).then((_) {
        // We are waiting and making absolutely no request unless:
        // Tor is disabled
        if (!enabled) {
          return false;
        }

        // ...or Tor circuit is established
        if (bootstrapped) {
          return false;
        }

        // This way we avoid making clearnet req's while Tor is initialising
        return true;
      }),
    );
  }

  void hello() {
    rust.hello();
  }
}
