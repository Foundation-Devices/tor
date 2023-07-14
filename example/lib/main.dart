import 'dart:async';
// example app deps, not necessarily needed for tor usage
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_socks_proxy/socks_proxy.dart'; // just for example; can use any socks5 proxy package, pick your favorite.
import 'package:tor/tor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late int sumResult;
  late Future<int> sumAsyncResult;

  final portController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Create the Tor class
    dynamic tor = Tor();

    // Start the Tor daemon
    tor.start();

    // TODO async example
    // sumAsyncResult = Future.delayed(Duration.zero, () {
    //   return 0;
    // }); // tor.sumAsync(3, 4);
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    portController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Text(
                  'Enter the port of your Tor daemon/SOCKS5 proxy and press connect'
                  'See the console logs for your port or ~/Documents/tor/tor.log',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                TextField(
                  controller: portController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'SOCKS5 proxy port',
                  ),
                ),
                spacerSmall,
                TextButton(
                    onPressed: () async {
                      // proxy -> "SOCKS5/SOCKS4/PROXY username:password@host:port;" or "DIRECT"
                      final http = createProxyHttpClient()
                        ..findProxy =
                            (url) => "SOCKS5 127.0.0.1:${portController.text}";
                      http
                          .getUrl(Uri.parse(
                              'https://raw.githubusercontent.com/tayoji-io/socks_proxy/master/README.md'))
                          .then((value) {
                            return value.close();
                          })
                          .then((value) {
                            return value.transform(utf8.decoder);
                          })
                          .then((value) {
                            return value.fold(
                                '',
                                (dynamic previous, element) =>
                                    previous + element);
                          })
                          .then((value) => print(value))
                          .catchError((e) => print(e));
                    },
                    child: Text("connect")),
                // TODO make test interactive (button, status indicator)
                // spacerSmall,
                // Text(
                //   'sum(1, 2) = $sumResult',
                //   style: textStyle,
                //   textAlign: TextAlign.center,
                // ),
                // TODO async example
                // spacerSmall,
                // FutureBuilder<int>(
                //   future: sumAsyncResult,
                //   builder: (BuildContext context, AsyncSnapshot<int> value) {
                //     final displayValue =
                //         (value.hasData) ? value.data : 'loading';
                //     return Text(
                //       'await sumAsync(3, 4) = $displayValue',
                //       style: textStyle,
                //       textAlign: TextAlign.center,
                //     );
                //   },
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
