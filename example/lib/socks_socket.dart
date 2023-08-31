import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A SOCKS5 socket.
///
/// This class is a wrapper around a [Socket] that connects to a SOCKS5 proxy
/// server and sends all data through the proxy.
///
/// This class is used to connect to the Tor proxy server.
///
/// Attributes:
///  - [proxyHost]: The host of the SOCKS5 proxy server.
///  - [proxyPort]: The port of the SOCKS5 proxy server.
///  - [_socksSocket]: The underlying [Socket] that connects to the SOCKS5 proxy
///  server.
///  - [_responseController]: A [StreamController] that listens to the
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

  /// A StreamController that listens to the _socksSocket and broadcasts
  final StreamController<List<int>> _responseController =
      StreamController.broadcast();

  /// Private constructor.
  SOCKSSocket._(this.proxyHost, this.proxyPort);

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
      {required String proxyHost, required int proxyPort}) async {
    // Create a SOCKS socket instance.
    var instance = SOCKSSocket._(proxyHost, proxyPort);

    // Initialize the SOCKS socket.
    await instance._init();

    // Return the SOCKS socket instance.
    return instance;
  }

  /// Constructor.
  SOCKSSocket({required this.proxyHost, required this.proxyPort}) {
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
    _socksSocket.listen(
      (data) {
        // Add the data to the response controller.
        _responseController.add(data);
      },
      onError: (e) {
        // Handle errors.
        if (e is Object) {
          _responseController.addError(e);
        }

        // If the error is not an object, send the error as a string.
        _responseController.addError("$e");
        // TODO make sure sending error as string is acceptable.
      },
      onDone: () {
        // Close the response controller when the socket is closed.
        _responseController.close();
      },
    );
  }

  /// Connects to the SOCKS socket.
  ///
  /// Returns:
  ///  A Future that resolves to void.
  Future<void> connect() async {
    // Greeting and method selection.
    _socksSocket.add([0x05, 0x01, 0x00]);

    // Wait for server response.
    var response = await _responseController.stream.first;

    // Check if the connection was successful.
    if (response[1] != 0x00) {
      throw Exception('socks_socket.connect(): Failed to connect to SOCKS5 proxy.');
    }
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
    // Connect command.
    var request = [
      0x05, // SOCKS version.
      0x01, // Connect command.
      0x00, // Reserved.
      0x03, // Domain name.
      domain.length,
      ...domain.codeUnits,
      (port >> 8) & 0xFF,
      port & 0xFF
    ];

    // Send the connect command to the SOCKS proxy server.
    _socksSocket.add(request);

    // Wait for server response.
    var response = await _responseController.stream.first;
    
    // Check if the connection was successful.
    if (response[1] != 0x00) {
      throw Exception('socks_socket.connectTo(): Failed to connect to target through SOCKS5 proxy.');
    }
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
    _socksSocket.add(data);
  }

  /// Sends the server.features command to the proxy server.
  ///
  /// This method is used to send the server.features command to the proxy
  /// server. This command is used to request the features of the proxy server.
  /// It serves as a demonstration of how to send commands to the proxy server.
  ///
  /// Returns:
  ///   A Future that resolves to void.
  Future<void> sendServerFeaturesCommand() async {
    // The server.features command.
    const String command =
        '{"jsonrpc":"2.0","id":"0","method":"server.features","params":[]}';

    // Send the command to the proxy server.
    _socksSocket.writeln(command);

    // Wait for the response from the proxy server.
    var responseData = await _responseController.stream.first;
    print("responseData: ${utf8.decode(responseData)}");
  }

  /// Closes the connection to the Tor proxy.
  ///
  /// Returns:
  ///  A Future that resolves to void.
  Future<void> close() async {
    // Ensure all data is sent before closing.
    await _socksSocket.flush();
    await _responseController.close();
    return await _socksSocket.close();
  }
}
