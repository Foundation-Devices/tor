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

import 'generated_bindings.dart';

/// Load the library.
///
/// This function is called by the Dart side to load the library.
///
/// Parameters:
///  - [name] (String): The name of the library.
///
/// Returns:
///   The library.
DynamicLibrary load(name) {
  if (Platform.isAndroid) {
    // Android is dynamically linked, so we need to load the library.
    return DynamicLibrary.open('lib$name.so');
  } else if (Platform.isLinux) {
    // Linux is dynamically linked, so we need to load the library.
    return DynamicLibrary.open('lib$name.so');
  } else if (Platform.isIOS || Platform.isMacOS) {
    // iOS and MacOS are statically linked, so it is the same as the current process.
    return DynamicLibrary.process();
  } else if (Platform.isWindows) {
    return DynamicLibrary.open('$name.dll');
  } else {
    // Unsupported platform.
    throw NotSupportedPlatform('${Platform.operatingSystem} is not supported!');
  }
}

/// An exception that is thrown when Tor couldn't bootstrap a working directory.
///
/// Parameters:
/// - [rustError] (String): The Rust error.
///
/// Returns:
///   A CouldntBootstrapDirectory exception.
class CouldntBootstrapDirectory implements Exception {
  /// The Rust error.
  String? rustError;

  /// Create a CouldntBootstrapDirectory exception.
  CouldntBootstrapDirectory({this.rustError});
}

/// An exception that is thrown when the platform is not supported.
///
/// Parameters:
/// - [s] (String): The error message.
///
/// Returns:
///   A NotSupportedPlatform exception.
class NotSupportedPlatform implements Exception {
  NotSupportedPlatform(String s);
}

/// A singleton class that represents the Tor client.
///
/// This class is called by the Dart side to represent the Tor client.  The Tor
/// client is a singleton.
///
/// Attributes:
/// - [_libName] (String): The name of the library.
/// - [_lib] (DynamicLibrary): The library.
/// - [_clientPtr] (Pointer<Int>): The client pointer.
/// - [_enabled] (bool): Whether the Tor client is enabled.
/// - [_started] (bool): Whether the Tor client is started.
/// - [_bootstrapped] (bool): Whether the Tor client is bootstrapped.
/// - [events] (StreamController): The events stream controller.
/// - [_proxyPort] (int): The port that the socks5 proxy is listening on.
/// - [_instance] (Tor): The Tor instance.
///
/// Methods:
/// - [Tor] (constructor): Create a Tor instance.
/// - [init]: Initialize the Tor client.
/// - [enable]: Enable the Tor client.
/// - [start]: Start the Tor client.
/// - [bootstrap]: Bootstrap the Tor client.
/// - [disable]: Disable the Tor client.
/// - [restart]: Restart the Tor client.
/// - [isReady]: Check if Tor is ready to make requests.
/// - [throwRustException]: Throw a Rust exception.
/// - [_getRustException]: Get a Rust exception.
/// - [hello]: Demonstrate calling a Rust function.
///
/// Throws:
/// - [CouldntBootstrapDirectory] if Tor couldn't bootstrap a working directory.
/// - [Exception] if Tor couldn't start.
/// - [unimplementedError] if restart is called.
/// - [NotSupportedPlatform] if the platform is not supported.
class Tor {
  /// The name of the library.
  static late String _libName = "tor_ffi";

  /// The library.
  static late DynamicLibrary _lib;

  /// The client pointer.
  Pointer<Int> _clientPtr = nullptr;

  /// Whether the Tor client is enabled.
  bool get enabled => _enabled;

  /// Whether the Tor client is started.
  bool _enabled = true;

  /// Whether the Tor client is started.
  bool get started => _started;

  /// Whether the Tor client is bootstrapped.
  bool _started = false;

  /// Whether the Tor client is bootstrapped.
  bool get bootstrapped => _bootstrapped;

  /// Whether the Tor client is bootstrapped.
  bool _bootstrapped = false;

  /// The events stream controller.
  final StreamController events = StreamController.broadcast();
  // This stream broadcast just the port for now (-1 if circuit not established)

  /// The port that the socks5 proxy is listening on.
  ///
  /// This gets set after the Tor client is started.
  ///
  /// Returns:
  ///   The port that the socks5 proxy is listening on, or -1 if the circuit is not established.
  int get port {
    if (!_enabled) {
      return -1;
    }
    return _proxyPort;
  }

  // The port that the socks5 proxy is listening on.
  //
  // This gets set after the Tor client is started.
  int _proxyPort = -1;

  /// The Tor instance.
  static final Tor _instance = Tor._internal();

  /// Get the Tor instance.
  ///
  /// This function is called by the Dart side to get the Tor instance.
  ///
  /// Returns:
  ///   The Tor instance.
  factory Tor() {
    return _instance;
  }

  /// Initialize the Tor client.
  ///
  /// This function is called by the Dart side to initialize the Tor client.
  ///
  /// Returns:
  ///   A future that completes when the Tor client is initialized, resolving to a Tor instance.
  ///   The Tor instance is a singleton.
  static Future<Tor> init({enabled = true}) async {
    var singleton = Tor._instance;
    singleton._enabled = enabled;
    return singleton;
  }

  /// Create a Tor instance.
  ///
  /// This function is called by the Dart side to create a Tor instance.
  Tor._internal() {
    // Load the library.
    _lib = load(_libName);

    print("Instance of Tor created!");
  }

  /// Enable the Tor client.
  ///
  /// This function is called by the Dart side to enable the Tor client.
  ///
  /// Returns:
  ///   A future that completes when the Tor client is enabled, resolving to `void`.
  Future<void> enable() async {
    // Set the enabled flag.
    _enabled = true;

    // Start the Tor client if it hasn't been started yet.
    if (!started) {
      start();
    }
  }

  /// Get a random unused port.
  ///
  /// This function is called by the Dart side to get a random unused port.
  ///
  /// Returns:
  ///   A future that completes when a random unused port is found, resolving to the port.
  Future<int> _getRandomUnusedPort({List<int> excluded = const []}) async {
    // Create a secure random number generator.
    var random = Random.secure();

    // The potential port.
    int potentialPort = 0;

    // Retry until we get a port that is not in the excluded list.
    retry:
    while (potentialPort <= 0 || excluded.contains(potentialPort)) {
      // Generate a random port.
      potentialPort = random.nextInt(65535);

      // Check if the port is available.
      try {
        // Bind to the port.
        var socket = await ServerSocket.bind("0.0.0.0", potentialPort);

        // Close the socket.
        socket.close();

        // Return the port.
        return potentialPort;
      } catch (_) {
        // If the port is not available, try again.
        continue retry;
      }
    }

    // If we get here, we couldn't find a port.
    return -1;
  }

  /// Start the Tor client.
  ///
  /// This function is called by the Dart side to start the Tor client.
  ///
  /// Returns:
  ///   A future that completes when the Tor client is started, resolving to `void`.
  Future<void> start() async {
    // Add the port to the stream.
    events.add(port);

    // Get the app's support directory.
    final Directory appSupportDir = await getApplicationSupportDirectory();

    // Create the state and cache directories.
    final stateDir =
        await Directory(appSupportDir.path + '/tor_state').create();
    final cacheDir =
        await Directory(appSupportDir.path + '/tor_cache').create();

    // Get a random unused port.
    int newPort = await _getRandomUnusedPort();

    // Start the Tor client.
    int ptr = await Isolate.run(() async {
      // Load the library.
      var lib = NativeLibrary(load(_libName));

      // Start the Tor client.
      final ptr = lib.tor_start(
          newPort,
          stateDir.path.toNativeUtf8() as Pointer<Char>,
          cacheDir.path.toNativeUtf8() as Pointer<Char>);

      // Throw an exception if the pointer is null.
      if (ptr == nullptr) {
        throwRustException(lib);
      }

      // Return the pointer.
      return ptr.address;
    });

    // Set the client pointer.
    _clientPtr = Pointer.fromAddress(ptr);

    // Set the started flag.
    _started = true;

    // Bootstrap the Tor client.
    bootstrap();

    // Set the port.
    _proxyPort = newPort;

    return;
  }

  /// This function is called by the Dart side to bootstrap the Tor client.
  ///
  /// Returns:
  ///   A future that completes when the Tor client is bootstrapped, resolving to `void`.
  Future<void> bootstrap() async {
    var lib = NativeLibrary(_lib);
    _bootstrapped = await lib.tor_bootstrap(_clientPtr);
    if (!bootstrapped) {
      throwRustException(lib);
    }
  }

  /// Disable the Tor client.
  ///
  /// This function is called by the Dart side to disable the Tor client.
  ///
  /// Returns:
  ///   `void`
  void disable() {
    _enabled = false;
  }

  /// Stop the Tor client.
  ///
  /// Throws:
  /// - `unimplementedError`
  void restart() {
    // TODO: arti seems to recover by itself and there is no client restart fn
    // TODO: but follow up with them if restart is truly unnecessary
    // if (enabled && started && circuitEstablished) {}
    throw UnimplementedError('Tor.restart(): Restart is not implemented yet');
  }

  /// Check if Tor is ready to make requests.
  ///
  /// This function is called by the Dart side to check if Tor is ready to make
  /// requests.
  ///
  /// It will wait until Tor is ready to make requests, or until Tor is disabled.
  ///
  /// Returns:
  ///   `true` if Tor is ready to make requests, `false` if Tor is disabled.
  ///
  /// Throws:
  /// - `CouldntBootstrapDirectory` if Tor couldn't bootstrap a working directory.
  /// - `Exception` if Tor couldn't start.
  Future<bool> isReady() async {
    // If Tor is disabled, return false.
    bool isReady = false;

    // Wait until Tor is ready to make requests, or until Tor is disabled.
    await Future.doWhile(() => Future.delayed(Duration(seconds: 1)).then((_) {
          // We are waiting and making absolutely no request unless:
          // Tor is disabled.
          if (!this.enabled) {
            isReady = false;
          }

          // ...or Tor circuit is established.
          if (this.bootstrapped) {
            isReady = false;
          }

          // This way we avoid making clearnet req's while Tor is initialising.
          isReady = true;

          return isReady;
        }));

    // Return whether Tor is ready to make requests.
    return isReady;
  }

  /// Throw a Rust exception.
  ///
  /// This function is called by the Dart side to throw a Rust exception.
  static throwRustException(NativeLibrary lib) {
    String rustError = lib.tor_last_error_message().cast<Utf8>().toDartString();

    throw _getRustException(rustError);
  }

  /// Get a Rust exception.
  ///
  /// This function is called by the Dart side to get a Rust exception.
  ///
  /// Returns:
  ///  A Rust exception.
  static Exception _getRustException(String rustError) {
    if (rustError.contains('Unable to bootstrap a working directory')) {
      return CouldntBootstrapDirectory(rustError: rustError);
    } else {
      return Exception(rustError);
    }
  }

  /// Demonstrate calling a Rust function.
  hello() {
    NativeLibrary(_lib).tor_hello();
  }

  Future<int> getRandomUnusedPort({List<int> excluded = const []}) async {
    final Random random = Random.secure();
    int? potentialPort;

    while (true) {
      potentialPort = random.nextInt(65535);
      if (!excluded.contains(potentialPort)) {
        ServerSocket? socket;
        try {
          socket = await ServerSocket.bind("0.0.0.0", potentialPort);

          // found unused port and return it
          return potentialPort;
        } catch (_) {
          // do nothing (continue looping)
        } finally {
          // close socket no matter what
          socket?.close();
        }
      }
    }

    return -1;
  }

  // WARNING probably not safe, just for demo purposes
  String generatePassword([int len = 32]) {
    const allowedChars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';

    var random = Random.secure();
    return String.fromCharCodes(Iterable.generate(len,
        (_) => allowedChars.codeUnitAt(random.nextInt(allowedChars.length))));
  }
}
