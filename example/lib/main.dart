import 'package:flutter/material.dart';
import 'dart:async';

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
                  'This calls a native function through FFI that is shipped as source in the package. '
                  'The native code must be built by running your platform\'s respective build script, see README.md.',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
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
