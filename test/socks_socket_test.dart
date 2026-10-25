// SPDX-FileCopyrightText: 2026 Foundation Devices Inc.
//
// SPDX-License-Identifier: MIT

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tor/socks_socket.dart';

const _ipv4Reply = [0x05, 0x00, 0x00, 0x01, 127, 0, 0, 1, 0x1F, 0x90];
final _ipv6Reply = [0x05, 0x00, 0x00, 0x04, ...List.filled(16, 0), 0x01, 0xBB];
final _domainReply = [
  0x05,
  0x00,
  0x00,
  0x03,
  11,
  ...ascii.encode('example.com'),
  0x00,
  0x50,
];

/// Feeds [reply] one byte at a time, as the most fragmented TCP delivery would.
void _expectCompleteOnlyAtEnd(
  List<int> reply,
  int? Function(List<int>) frameLength,
) {
  for (var split = 0; split < reply.length; split++) {
    expect(frameLength(reply.sublist(0, split)), isNull,
        reason: 'split $split');
  }
  expect(frameLength(reply), reply.length);
}

void main() {
  group('socks5MethodReplyLength', () {
    test('needs the whole two-byte reply', () {
      _expectCompleteOnlyAtEnd(const [0x05, 0x00], socks5MethodReplyLength);
    });

    test('rejects a wrong version from its first byte', () {
      expect(() => socks5MethodReplyLength(const [0x04]),
          throwsA(isA<SOCKSException>()));
    });

    test('rejects a refused authentication method', () {
      expect(() => socks5MethodReplyLength(const [0x05, 0xFF]),
          throwsA(isA<SOCKSException>()));
    });
  });

  group('socks5ConnectReplyLength', () {
    for (final (name, reply) in [
      ('IPv4', _ipv4Reply),
      ('IPv6', _ipv6Reply),
      ('domain', _domainReply),
    ]) {
      test('needs the whole $name reply at every split', () {
        _expectCompleteOnlyAtEnd(reply, socks5ConnectReplyLength);
      });

      test('leaves coalesced destination bytes after the $name reply', () {
        final buffer = [...reply, ...ascii.encode('payload')];
        expect(socks5ConnectReplyLength(buffer), reply.length);
      });
    }

    test('reports a refusal with its reply code', () {
      expect(
        () => socks5ConnectReplyLength(const [0x05, 0x05]),
        throwsA(isA<SOCKSException>()
            .having((e) => e.replyCode, 'replyCode', 0x05)),
      );
    });

    test('rejects malformed replies', () {
      for (final reply in const [
        [0x04, 0x00, 0x00, 0x01],
        [0x05, 0x00, 0x01, 0x01],
        [0x05, 0x00, 0x00, 0x02],
        [0x05, 0x00, 0x00, 0x03, 0x00],
      ]) {
        expect(() => socks5ConnectReplyLength(reply),
            throwsA(isA<SOCKSException>()),
            reason: '$reply');
      }
    });
  });

  group('socks5ConnectRequest', () {
    test('encodes the domain and port', () {
      expect(
        socks5ConnectRequest('a.io', 443),
        [0x05, 0x01, 0x00, 0x03, 4, ...ascii.encode('a.io'), 0x01, 0xBB],
      );
    });

    test('rejects domains and ports SOCKS5 cannot carry', () {
      for (final (domain, port) in [
        ('', 80),
        ('a' * 256, 80),
        ('bücher.de', 80),
        ('a.io', 0),
        ('a.io', 65536),
      ]) {
        expect(() => socks5ConnectRequest(domain, port), throwsArgumentError,
            reason: '$domain:$port');
      }
    });
  });

  group('SOCKSSocket over a fragmenting proxy', () {
    late ServerSocket proxy;

    tearDown(() => proxy.close());

    /// A proxy that writes each reply one byte at a time and coalesces
    /// [destinationData] with the final CONNECT reply byte.
    Future<void> startProxy({
      List<int> connectReply = _ipv4Reply,
      List<int> destinationData = const [],
    }) async {
      proxy = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      proxy.listen((client) async {
        final incoming = StreamIterator(client);
        final received = <int>[];
        Future<void> readAtLeast(int count) async {
          while (received.length < count && await incoming.moveNext()) {
            received.addAll(incoming.current);
          }
        }

        Future<void> dribble(List<int> bytes) async {
          for (final byte in bytes) {
            client.add([byte]);
            await client.flush();
            await Future<void>.delayed(const Duration(milliseconds: 2));
          }
        }

        await readAtLeast(3);
        await dribble(const [0x05, 0x00]);
        await readAtLeast(3 + socks5ConnectRequest('example.com', 80).length);
        await dribble(connectReply.sublist(0, connectReply.length - 1));
        client.add([connectReply.last, ...destinationData]);
        await client.flush();
      });
    }

    test('completes the handshake and keeps coalesced destination bytes',
        () async {
      await startProxy(destinationData: ascii.encode('hello'));
      final socket = await SOCKSSocket.create(
        proxyHost: InternetAddress.loopbackIPv4.address,
        proxyPort: proxy.port,
      );
      await socket.connect();
      await socket.connectTo('example.com', 80);

      final data = await socket.inputStream.first;
      expect(ascii.decode(data), 'hello');
      await socket.close();
    });

    test('raises a typed error when the proxy refuses the target', () async {
      await startProxy(connectReply: const [0x05, 0x05, 0x00, 0x01]);
      final socket = await SOCKSSocket.create(
        proxyHost: InternetAddress.loopbackIPv4.address,
        proxyPort: proxy.port,
      );
      await socket.connect();

      await expectLater(
        socket.connectTo('example.com', 80),
        throwsA(isA<SOCKSException>()
            .having((e) => e.replyCode, 'replyCode', 0x05)),
      );
      await socket.close();
    });

    test('refuses proxy bytes that would precede the TLS handshake', () async {
      await startProxy(destinationData: ascii.encode('early'));
      final socket = await SOCKSSocket.create(
        proxyHost: InternetAddress.loopbackIPv4.address,
        proxyPort: proxy.port,
        sslEnabled: true,
      );
      await socket.connect();

      await expectLater(
        socket.connectTo('example.com', 443),
        throwsA(isA<SOCKSException>()),
      );
      // No TLS socket was created, so close only the plain one.
      socket.sslEnabled = false;
      await socket.close();
    });
  });
}
