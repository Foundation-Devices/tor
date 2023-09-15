// SPDX-FileCopyrightText: 2022 Foundation Devices Inc.
//
// SPDX-License-Identifier: GPL-3.0-or-later

import 'dart:async';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:ffi/ffi.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tor/tor_bindings_generated.dart';

DynamicLibrary load(name) {
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$name.so');
  } else if (Platform.isIOS || Platform.isMacOS) {
    return DynamicLibrary.open('$name.framework/$name');
  } else if (Platform.isWindows) {
    return DynamicLibrary.open('$name.dll');
  } else {
    throw NotSupportedPlatform('${Platform.operatingSystem} is not supported!');
  }
}

class CouldntBootstrapDirectory implements Exception {
  String? rustError;

  CouldntBootstrapDirectory({this.rustError});
}

class NotSupportedPlatform implements Exception {
  NotSupportedPlatform(String s);
}

class Tor {
  static const String _libName = "tor";
  static late DynamicLibrary _lib;

  Pointer<Int> _clientPtr = nullptr;

  /// Flag to indicate that a Tor should be started.
  bool get started => _started;

  /// Getter for the started flag.
  bool _started = false;

  /// Flag to indicate that Tor has started.
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
  /// This stream broadcast just the port for now (-1 if circuit not established)
  final StreamController events = StreamController.broadcast();

  /// Getter for the proxy port.
  ///
  /// Returns -1 if Tor is not enabled or if the circuit is not established.
  ///
  /// Returns the proxy port if Tor is enabled and the circuit is established.
  ///
  /// This is the port that should be used for all requests.
  int get port {
    if (!_enabled) {
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
  static Future<Tor> init({enabled = true}) async {
    var singleton = Tor._instance;
    singleton._enabled = enabled;
    return singleton;
  }

  /// Private constructor for the Tor class.
  Tor._internal() {
    _lib = load(_libName);
    print("Instance of Tor created!");
  }

  /// Start the Tor service.
  Future<void> enable() async {
    _enabled = true;
    if (!started) {
      return await start();
    }
  }

  Future<int> _getRandomUnusedPort({List<int> excluded = const []}) async {
    var random = Random.secure();
    int potentialPort = 0;

    retry:
    while (potentialPort <= 0 || excluded.contains(potentialPort)) {
      potentialPort = random.nextInt(65535);
      try {
        var socket = await ServerSocket.bind("0.0.0.0", potentialPort);
        socket.close();
        return potentialPort;
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
  Future<void> start() async {
    // Send the port to the events stream.
    events.add(port);

    // Set the state and cache directories.
    final Directory appSupportDir = await getApplicationSupportDirectory();
    final stateDir =
        await Directory('${appSupportDir.path}/tor_state').create();
    final cacheDir =
        await Directory('${appSupportDir.path}/tor_cache').create();

    // Generate a random port.
    int newPort = await _getRandomUnusedPort();

    // Start the Tor service in an isolate.
    int ptr = await Isolate.run(() async {
      // Load the Tor library.
      var lib = NativeLibrary(load(_libName));

      // Start the Tor service.
      final ptr = lib.tor_start(
          newPort,
          stateDir.path.toNativeUtf8() as Pointer<Char>,
          cacheDir.path.toNativeUtf8() as Pointer<Char>);

      // Throw an exception if the Tor service fails to start.
      if (ptr == nullptr) {
        throwRustException(lib);
      }

      // Return the pointer.
      return ptr.address;
    });

    // Set the client pointer and started flag.
    _clientPtr = Pointer.fromAddress(ptr);
    _started = true;

    // Bootstrap the Tor service.
    bootstrap();

    // Set the proxy port and enabled flag.
    _proxyPort = newPort;
    _enabled = true;
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
  void bootstrap() {
    // Load the Tor library.
    final lib = NativeLibrary(_lib);

    // Bootstrap the Tor service.
    _bootstrapped = lib.tor_bootstrap(_clientPtr);

    // Throw an exception if the Tor service fails to bootstrap.
    if (!bootstrapped) {
      throwRustException(lib);
    }
  }

  // TODO: this doesn't actually shut tor down
  void disable() {
    _enabled = false;
  }

  void restart() {
    // TODO: arti seems to recover by itself and there is no client restart fn
    // TODO: but follow up with them if restart is truly unnecessary
    // if (enabled && started && circuitEstablished) {}
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

  static throwRustException(NativeLibrary lib) {
    String rustError = lib.tor_last_error_message().cast<Utf8>().toDartString();

    throw _getRustException(rustError);
  }

  static Exception _getRustException(String rustError) {
    if (rustError.contains('Unable to bootstrap a working directory')) {
      return CouldntBootstrapDirectory(rustError: rustError);
    } else {
      return Exception(rustError);
    }
  }

  void hello() {
    NativeLibrary(_lib).tor_hello();
  }
}
