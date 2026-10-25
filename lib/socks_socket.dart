// SPDX-FileCopyrightText: 2024 Cypher Stack LLC
//
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

/// A malformed or refused SOCKS5 handshake.
class SOCKSException implements Exception {
  SOCKSException(this.message, {this.replyCode});

  final String message;

  /// The REP field of a refused CONNECT reply, when the proxy sent one.
  final int? replyCode;

  @override
  String toString() => 'SOCKSException: $message';
}

/// Length of the complete method-selection reply at the start of [buffer], or
/// null while more bytes are needed. Throws [SOCKSException] when invalid.
@visibleForTesting
int? socks5MethodReplyLength(List<int> buffer) {
  if (buffer.isNotEmpty && buffer[0] != 0x05) {
    throw SOCKSException('unexpected SOCKS version ${buffer[0]}');
  }
  if (buffer.length < 2) return null;
  if (buffer[1] != 0x00) {
    throw SOCKSException('proxy refused the no-authentication method');
  }
  return 2;
}

/// Length of the complete CONNECT reply at the start of [buffer], including
/// its variable-length bound address, or null while more bytes are needed.
/// Throws [SOCKSException] for a refusal or a malformed reply.
@visibleForTesting
int? socks5ConnectReplyLength(List<int> buffer) {
  if (buffer.isNotEmpty && buffer[0] != 0x05) {
    throw SOCKSException('unexpected SOCKS version ${buffer[0]}');
  }
  if (buffer.length >= 2 && buffer[1] != 0x00) {
    throw SOCKSException('proxy refused the connection', replyCode: buffer[1]);
  }
  if (buffer.length >= 3 && buffer[2] != 0x00) {
    throw SOCKSException('invalid reserved byte ${buffer[2]}');
  }
  if (buffer.length < 4) return null;

  final int addressLength;
  switch (buffer[3]) {
    case 0x01:
      addressLength = 4;
    case 0x04:
      addressLength = 16;
    case 0x03:
      if (buffer.length < 5) return null;
      if (buffer[4] == 0) throw SOCKSException('empty bound domain');
      addressLength = 1 + buffer[4];
    default:
      throw SOCKSException('unknown address type ${buffer[3]}');
  }
  final length = 4 + addressLength + 2;
  return buffer.length >= length ? length : null;
}

/// The CONNECT request for [domain]:[port]. Throws [ArgumentError] for a
/// domain SOCKS5 cannot carry or a port outside 1-65535.
@visibleForTesting
List<int> socks5ConnectRequest(String domain, int port) {
  final name = domain.codeUnits;
  if (name.isEmpty || name.length > 255 || name.any((unit) => unit > 0x7F)) {
    throw ArgumentError.value(domain, 'domain', 'must be 1-255 ASCII bytes');
  }
  if (port < 1 || port > 0xFFFF) {
    throw ArgumentError.value(port, 'port', 'must be 1-65535');
  }
  return [
    0x05, // SOCKS version.
    0x01, // Connect command.
    0x00, // Reserved.
    0x03, // Domain name.
    name.length,
    ...name,
    (port >> 8) & 0xFF,
    port & 0xFF
  ];
}

/// A SOCKS5 socket.
///
/// A Dart 3 Socket wrapper that implements the SOCKS5 protocol.  Now with SSL!
///
/// Properties:
///  - [proxyHost]: The host of the SOCKS5 proxy server.
///  - [proxyPort]: The port of the SOCKS5 proxy server.
///  - [_socksSocket]: The underlying Socket that connects to the SOCKS5 proxy
///  server.
///  - [_responseController]: A StreamController that listens to the
///  [_socksSocket] and broadcasts the response.
///
/// Methods:
/// - connect: Connects to the SOCKS5 proxy server.
/// - connectTo: Connects to the specified [domain] and [port] through the
/// SOCKS5 proxy server.
/// - write: Converts [object] to a String by invoking [Object.toString] and
/// sends the encoding of the result to the socket.
/// - sendServerFeaturesCommand: Sends the server.features command to the
/// proxy server.
/// - close: Closes the connection to the Tor proxy.
///
/// Usage:
/// ```dart
/// // Instantiate a socks socket at localhost and on the port selected by the
/// // tor service.
/// var socksSocket = await SOCKSSocket.create(
///  proxyHost: InternetAddress.loopbackIPv4.address,
///  proxyPort: tor.port,
///  // sslEnabled: true, // For SSL connections.
///  );
///
/// // Connect to the socks instantiated above.
/// await socksSocket.connect();
///
/// // Connect to bitcoincash.stackwallet.com on port 50001 via socks socket.
/// await socksSocket.connectTo(
/// 'bitcoincash.stackwallet.com', 50001);
///
/// // Send a server features command to the connected socket, see method for
/// // more specific usage example..
/// await socksSocket.sendServerFeaturesCommand();
/// await socksSocket.close();
/// ```
///
/// See also:
/// - SOCKS5 protocol(https://www.ietf.org/rfc/rfc1928.txt)
class SOCKSSocket {
  /// The host of the SOCKS5 proxy server.
  final String proxyHost;

  /// The port of the SOCKS5 proxy server.
  final int proxyPort;

  /// The underlying Socket that connects to the SOCKS5 proxy server.
  late final Socket _socksSocket;

  /// Getter for the underlying Socket that connects to the SOCKS5 proxy server.
  Socket get socket => sslEnabled ? _secureSocksSocket : _socksSocket;

  /// A wrapper around the _socksSocket that enables SSL connections.
  late final Socket _secureSocksSocket;

  /// A StreamController that listens to the _socksSocket and broadcasts.
  late final StreamController<List<int>> _responseController =
      StreamController.broadcast(onListen: _flushPending);

  /// Destination bytes received while nothing listens, such as bytes the
  /// proxy coalesced with its CONNECT reply; delivered to the first listener.
  final List<int> _pending = [];

  /// Proxy bytes not yet consumed by the SOCKS5 handshake.
  final List<int> _handshakeBuffer = [];
  bool _handshakeDone = false;
  Object? _handshakeError;
  Completer<void>? _handshakeWaiter;

  /// A StreamController that listens to the _secureSocksSocket and broadcasts.
  final StreamController<List<int>> _secureResponseController =
      StreamController.broadcast();

  /// Getter for the StreamController that listens to the _socksSocket and
  /// broadcasts, or the _secureSocksSocket and broadcasts if SSL is enabled.
  StreamController<List<int>> get responseController =>
      sslEnabled ? _secureResponseController : _responseController;

  /// A StreamSubscription that listens to the _socksSocket or the
  /// _secureSocksSocket if SSL is enabled.
  StreamSubscription<List<int>>? _subscription;

  /// Getter for the StreamSubscription that listens to the _socksSocket or the
  /// _secureSocksSocket if SSL is enabled.
  StreamSubscription<List<int>>? get subscription => _subscription;

  /// Is SSL enabled?
  bool sslEnabled;

  /// Private constructor.
  SOCKSSocket._(this.proxyHost, this.proxyPort, this.sslEnabled);

  /// Provides a stream of data as `List<int>`.
  Stream<List<int>> get inputStream => sslEnabled
      ? _secureResponseController.stream
      : _responseController.stream;

  /// Provides a StreamSink compatible with `List<int>` for sending data.
  StreamSink<List<int>> get outputStream {
    // Create a simple StreamSink wrapper for _socksSocket and
    // _secureSocksSocket that accepts List<int> and forwards it to write method.
    var sink = StreamController<List<int>>();
    sink.stream.listen((data) {
      if (sslEnabled) {
        _secureSocksSocket.add(data);
      } else {
        _socksSocket.add(data);
      }
    });
    return sink.sink;
  }

  /// Creates a SOCKS5 socket to the specified [proxyHost] and [proxyPort].
  ///
  /// This method is a factory constructor that returns a Future that resolves
  /// to a SOCKSSocket instance.
  ///
  /// Parameters:
  /// - [proxyHost]: The host of the SOCKS5 proxy server.
  /// - [proxyPort]: The port of the SOCKS5 proxy server.
  ///
  /// Returns:
  ///  A Future that resolves to a SOCKSSocket instance.
  static Future<SOCKSSocket> create(
      {required String proxyHost,
      required int proxyPort,
      bool sslEnabled = false}) async {
    // Create a SOCKS socket instance.
    var instance = SOCKSSocket._(proxyHost, proxyPort, sslEnabled);

    // Initialize the SOCKS socket.
    await instance._init();

    // Return the SOCKS socket instance.
    return instance;
  }

  /// Constructor.
  SOCKSSocket(
      {required this.proxyHost,
      required this.proxyPort,
      required this.sslEnabled}) {
    _init();
  }

  /// Initializes the SOCKS socket.
  ///
  /// This method is a private method that is called by the constructor.
  ///
  /// Returns:
  ///   A Future that resolves to void.
  Future<void> _init() async {
    // Connect to the SOCKS proxy server.
    _socksSocket = await Socket.connect(
      proxyHost,
      proxyPort,
    );

    // Listen to the socket.
    _subscription = _socksSocket.listen(
      (data) {
        if (!_handshakeDone) {
          _handshakeBuffer.addAll(data);
          _wakeHandshake();
          return;
        }
        _deliver(data);
      },
      onError: (e) {
        if (!_handshakeDone) {
          _handshakeError = e;
          _wakeHandshake();
          return;
        }

        // Handle errors.
        if (e is Object) {
          _responseController.addError(e);
        }

        // If the error is not an object, send the error as a string.
        _responseController.addError("$e");
        // TODO make sure sending error as string is acceptable.
      },
      onDone: () {
        if (!_handshakeDone) {
          _handshakeError ??=
              SOCKSException('proxy closed the connection during handshake');
          _wakeHandshake();
        }
        // Close the response controller when the socket is closed.
        // _responseController.close();
      },
    );
  }

  void _wakeHandshake() {
    final waiter = _handshakeWaiter;
    _handshakeWaiter = null;
    waiter?.complete();
  }

  /// Waits until [frameLength] finds a complete reply at the start of the
  /// handshake buffer, then removes and returns it. TCP may split or coalesce
  /// replies at any byte, so one socket event is never assumed to be a frame.
  Future<List<int>> _readFrame(int? Function(List<int>) frameLength) async {
    while (true) {
      final length = frameLength(_handshakeBuffer);
      if (length != null) {
        final frame = _handshakeBuffer.sublist(0, length);
        _handshakeBuffer.removeRange(0, length);
        return frame;
      }
      final error = _handshakeError;
      if (error != null) throw error;
      final waiter = Completer<void>();
      _handshakeWaiter = waiter;
      await waiter.future;
    }
  }

  void _deliver(List<int> data) {
    if (_responseController.hasListener) {
      _responseController.add(data);
    } else {
      _pending.addAll(data);
    }
  }

  void _flushPending() {
    if (_pending.isEmpty) return;
    final data = List<int>.of(_pending);
    _pending.clear();
    _responseController.add(data);
  }

  /// Connects to the SOCKS socket.
  ///
  /// Returns:
  ///  A Future that resolves to void.
  Future<void> connect() async {
    // Greeting and method selection.
    _socksSocket.add([0x05, 0x01, 0x00]);

    // Wait for the complete method-selection reply; it is validated as read.
    await _readFrame(socks5MethodReplyLength);
  }

  /// Connects to the specified [domain] and [port] through the SOCKS socket.
  ///
  /// Parameters:
  /// - [domain]: The domain to connect to.
  /// - [port]: The port to connect to.
  ///
  /// Returns:
  ///   A Future that resolves to void.
  Future<void> connectTo(String domain, int port) async {
    // Onion services provide their own end-to-end encryption, so disable the
    // TLS upgrade when connecting to a .onion domain.
    if (domain.endsWith('.onion')) {
      sslEnabled = false;
    }

    // Connect command, validated before anything is written.
    final request = socks5ConnectRequest(domain, port);

    // Send the connect command to the SOCKS proxy server.
    _socksSocket.add(request);

    // Wait for the complete CONNECT reply; a refusal throws SOCKSException.
    await _readFrame(socks5ConnectReplyLength);
    _handshakeDone = true;
    final leftover = List<int>.of(_handshakeBuffer);
    _handshakeBuffer.clear();

    // The TLS client speaks first, so destination bytes before its hello can
    // only come from a misbehaving proxy and must not reach the TLS layer.
    if (sslEnabled && leftover.isNotEmpty) {
      throw SOCKSException('proxy sent data before the TLS handshake');
    }
    if (leftover.isNotEmpty) _deliver(leftover);

    // Upgrade to SSL if needed.
    if (sslEnabled) {
      // Upgrade to SSL.
      _secureSocksSocket = await SecureSocket.secure(
        _socksSocket,
        host: domain,
        // onBadCertificate: (_) => true, // Uncomment this to bypass certificate validation (NOT recommended for production).
      );

      // Listen to the secure socket.
      _subscription = _secureSocksSocket.listen(
        (data) {
          // Add the data to the response controller.
          _secureResponseController.add(data);
        },
        onError: (e) {
          // Handle errors.
          if (e is Object) {
            _secureResponseController.addError(e);
          }

          // If the error is not an object, send the error as a string.
          _secureResponseController.addError("$e");
          // TODO make sure sending error as string is acceptable.
        },
        onDone: () {
          // Close the response controller when the socket is closed.
          _secureResponseController.close();
        },
      );
    }

    return;
  }

  /// Converts [object] to a String by invoking [Object.toString] and
  /// sends the encoding of the result to the socket.
  ///
  /// Parameters:
  /// - [object]: The object to write to the socket.
  ///
  /// Returns:
  ///  A Future that resolves to void.
  void write(Object? object) {
    // Don't write null.
    if (object == null) return;

    // Write the data to the socket.
    List<int> data = utf8.encode(object.toString());
    if (sslEnabled) {
      _secureSocksSocket.add(data);
    } else {
      _socksSocket.add(data);
    }
  }

  /// Closes the connection to the Tor proxy.
  ///
  /// Returns:
  ///  A Future that resolves to void.
  Future<void> close() async {
    // Ensure all data is sent before closing.
    try {
      if (sslEnabled) {
        await _secureSocksSocket.flush();
      }
      await _socksSocket.flush();
    } finally {
      await _subscription?.cancel();
      await _socksSocket.close();
      _responseController.close();
      if (sslEnabled) {
        _secureResponseController.close();
      }
    }
  }

  StreamSubscription<List<int>> listen(
    void Function(List<int> data)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return sslEnabled
        ? _secureResponseController.stream.listen(
            onData,
            onError: onError,
            onDone: onDone,
            cancelOnError: cancelOnError,
          )
        : _responseController.stream.listen(
            onData,
            onError: onError,
            onDone: onDone,
            cancelOnError: cancelOnError,
          );
  }

  /// Sends the server.features command to the proxy server.
  ///
  /// This demos how to send the server.features command.  Use as an example
  /// for sending other commands.
  ///
  /// Returns:
  ///   A Future that resolves to void.
  Future<void> sendServerFeaturesCommand() async {
    // The server.features command.
    const String command =
        '{"jsonrpc":"2.0","id":"0","method":"server.features","params":[]}';

    if (!sslEnabled) {
      // Send the command to the proxy server.
      _socksSocket.writeln(command);

      // Wait for the response from the proxy server.
      var responseData = await _responseController.stream.first;
      if (kDebugMode) {
        print("responseData: ${utf8.decode(responseData)}");
      }
    } else {
      // Send the command to the proxy server.
      _secureSocksSocket.writeln(command);

      // Wait for the response from the proxy server.
      var responseData = await _secureResponseController.stream.first;
      if (kDebugMode) {
        print("secure responseData: ${utf8.decode(responseData)}");
      }
    }

    return;
  }
}
