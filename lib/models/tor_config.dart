import 'dart:math';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

class TorConfig {
  final String dataDirectory;
  final String logFile;
  final int socksPort;
  final int controlPort;
  final String password;
  final int clientRejectInternalAddresses;

  TorConfig({
    required this.dataDirectory,
    required this.logFile,
    required this.socksPort,
    required this.controlPort,
    required this.password,
    this.clientRejectInternalAddresses = 1,
  });

  @override
  String toString() {
    String torrc = 'DataDirectory ' +
        this.dataDirectory +
        '\n' +
        'Log notice file ' +
        this.logFile +
        '\n' +
        'SocksPort ' +
        "${this.socksPort}" +
        '\n' +
        'ControlPort ' +
        "${this.controlPort}" +
        '\n' +
        'HashedControlPassword ' +
        generatePasswordHash(this.password) +
        '\n' +
        "ClientRejectInternalAddresses ${this.clientRejectInternalAddresses}";
    return torrc;
  }

  static String generatePasswordHash(String password) {
    //https://tor.stackexchange.com/a/22591
    var random = Random.secure();

    // Obtain 8 random bytes from the system as salt
    var salt = List<int>.generate(8, (i) => random.nextInt(256));

    // Append the bytes of the user specified password to the salt
    var salted = salt + password.codeUnits;

    // Repeat this sequence until the length is 65536 (0x10000) bytes
    List<int> longSalted = [];
    while (longSalted.length < 65536) {
      longSalted.addAll(salted);
    }

    // If repeating the sequence doesn't exactly end up at this number, cut off any excess bytes
    // Hash the sequence using SHA1
    var digest = sha1.convert(longSalted.sublist(0, 65536));

    // Your hashed control password will be "16:" + Hex(Salt) + "60" + Hex(Sha1)
    // where + is string concatenation and Hex() is "convert bytes to uppercase hexadecimal"
    var hashed = '16:' +
        hex.encode(salt).toUpperCase() +
        '60' +
        hex.encode(digest.bytes).toUpperCase();
    return hashed;
  }
}
