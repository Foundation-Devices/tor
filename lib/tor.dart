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
  Future<void>? _bootstrapInFlight;

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

  Future<int> _getRandomUnusedPort({List<int> excluded = const []}) async {
    int port = 0;

    retry:
    while (port == 0 || excluded.contains(port)) {
      try {
        var socket = await ServerSocket.bind("0.0.0.0", 0);
        port = socket.port;
        socket.close();
        return port;
      } catch (_) {
        continue retry;
      }
    }

    return -1;
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

    final inFlight = _startInFlight;
    if (inFlight != null) return inFlight;

    late final Future<void> start;
    start = _startInternal().whenComplete(() {
      if (identical(_startInFlight, start)) {
        _startInFlight = null;
      }
    });
    _startInFlight = start;
    return start;
  }

  Future<void> _startInternal() async {
    broadcastState();

    await ensureRustLibInit();

    // Set the state and cache directories.
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final stateDir =
        await Directory('${appSupportDir.path}/tor_state').create();
    final cacheDir =
        await Directory('${appSupportDir.path}/tor_cache').create();

    // Generate a random port.
    int newPort = await _getRandomUnusedPort();

    try {
      // Start Tor - this is a blocking operation
      final torInstance = await rust.startTor(
        socksPort: newPort,
        stateDir: stateDir.path,
        cacheDir: cacheDir.path,
      );

      _client = torInstance.client;
      _proxy = torInstance.proxy;
      _proxyPort = torInstance.socksPort;
      // The getters above clone; free the container now instead of at GC so
      // it cannot keep an extra client reference (and dir.lock) alive.
      torInstance.dispose();
      _started = true;
      _bootstrapped = true; // startTor creates a bootstrapped client

      broadcastState();
    } on rust.TorError catch (e) {
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
    final inFlight = _bootstrapInFlight;
    if (inFlight != null) return inFlight;

    late final Future<void> bootstrap;
    bootstrap = _bootstrapInternal().whenComplete(() {
      if (identical(_bootstrapInFlight, bootstrap)) {
        _bootstrapInFlight = null;
      }
    });
    _bootstrapInFlight = bootstrap;
    return bootstrap;
  }

  Future<void> _bootstrapInternal() async {
    if (_client == null) {
      throw ClientNotActive();
    }

    try {
      await rust.bootstrap(client: _client!);
      _bootstrapped = true;
      broadcastState();
    } on rust.TorError catch (e) {
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
  Future<void> stop() async {
    final proxy = _proxy;
    final client = _client;

    // Stop publishing the route before awaiting native shutdown so callers
    // cannot start new work against a proxy that is being torn down.
    _proxy = null;
    _client = null;
    _proxyPort = -1;
    _started = false;
    _bootstrapped = false;
    broadcastState();

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

  Future<void> setClientDormant(bool dormant) async {
    if (_client == null || !started || !bootstrapped) {
      throw ClientNotActive();
    }

    await rust.setDormant(client: _client!, softMode: dormant);
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
            }));
  }

  void hello() {
    rust.hello();
  }
}
