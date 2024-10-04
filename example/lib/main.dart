// SPDX-FileCopyrightText: 2023 Foundation Devices Inc.
// SPDX-FileCopyrightText: 2024 Foundation Devices Inc.
//
// SPDX-License-Identifier: MIT

// Flutter dependencies not necessarily needed for tor usage:
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
// Example application dependencies you can replace with any that works for you:
import 'package:socks5_proxy/socks_client.dart';
import 'package:tor/socks_socket.dart';
// The only real import needed for basic usage:
import 'package:tor/tor.dart'; // This would go at the top, but dart autoformatter doesn't like it there.

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Home(),
    );
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _MyAppState();
}

class _MyAppState extends State<Home> {
  // Flag to track if tor has started.
  bool torStarted = false;

  // Set the default text for the host input field.
  final hostController = TextEditingController(text: 'https://icanhazip.com/');
  // https://check.torproject.org is another good option.

  String? exitNodeAddress;

  Future<void> startTor() async {
    await Tor.init();

    // Start the proxy
    await Tor.instance.start();

    // Toggle started flag.
    setState(() {
      torStarted = Tor.instance.started; // Update flag
    });

    print('Done awaiting; tor should be running');

    // Fetch the exit node address.
    try {
      String? address = await Tor.instance.getExitNode();
      // getExitNode above should return like: [1.2.3.4:5 ed25519:Q6+... $7...]
      setState(() {
        if (address != null && address!.contains(":")) {
          // Strip just the IP out of the above.
          address = address?.split(":")[0].substring(1);
        }
        exitNodeAddress = address;
      });
    } catch (e) {
      print('Error getting exit node address: $e');
      setState(() {
        exitNodeAddress = 'Error retrieving exit node address';
      });
    }
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    hostController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const spacerSmall = SizedBox(height: 10);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tor example'),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  TextButton(
                    onPressed: torStarted
                        ? null
                        : () async {
                            unawaited(
                              showDialog(
                                barrierDismissible: false,
                                context: context,
                                builder: (_) => const Dialog(
                                  child: Padding(
                                    padding: EdgeInsets.all(20.0),
                                    child: Text("Starting tor..."),
                                  ),
                                ),
                              ),
                            );

                            final time = DateTime.now();

                            print("NOW: $time");

                            await startTor();

                            print("Starting tor took "
                                "${DateTime.now().difference(time).inSeconds} "
                                "seconds. Proxy running on port ${Tor.instance.port}");

                            if (mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    child: const Text("Start"),
                  ),
                  TextButton(
                    onPressed: !torStarted
                        ? null
                        : () async {
                            await Tor.instance.stop();
                            setState(() {
                              torStarted = false; // Update flag
                            });
                          },
                    child: const Text("Stop"),
                  ),
                  // Display the exit node address.
                  if (exitNodeAddress != null) ...[
                    spacerSmall,
                    Text(
                      'Exit Node: $exitNodeAddress',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ],
              ),
              Row(
                children: [
                  // Host input field.
                  Expanded(
                    child: TextField(
                      controller: hostController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Host to request',
                      ),
                    ),
                  ),
                  spacerSmall,
                  TextButton(
                    onPressed: torStarted
                        ? () async {
                            // `socks5_proxy` package example, use another socks5
                            // connection of your choice.

                            // Create HttpClient object
                            final client = HttpClient();

                            // Assign connection factory.
                            SocksTCPClient.assignToHttpClient(client, [
                              ProxySettings(InternetAddress.loopbackIPv4,
                                  Tor.instance.port,
                                  password:
                                      null), // TODO Need to get from tor config file.
                            ]);

                            // GET request.
                            final url = Uri.parse(hostController.text);
                            final request = await client.getUrl(url);
                            final response = await request.close();

                            // Print response.
                            var responseString =
                                await utf8.decodeStream(response);
                            print(responseString);
                            // If host input left to default icanhazip.com, a Tor
                            // exit node IP should be printed to the console.
                            //
                            // https://check.torproject.org is also good for
                            // doublechecking torability.

                            // Close client
                            client.close();
                          }
                        : null,
                    child: const Text("Make proxied request"),
                  ),
                ],
              ),
              spacerSmall,
              TextButton(
                onPressed: torStarted
                    ? () async {
                        // Instantiate a socks socket at localhost and on the port selected by the tor service.
                        var socksSocket = await SOCKSSocket.create(
                          proxyHost: InternetAddress.loopbackIPv4.address,
                          proxyPort: Tor.instance.port,
                          sslEnabled: true, // For SSL connections.
                        );

                        // Connect to the socks instantiated above.
                        await socksSocket.connect();

                        // Connect to bitcoin.stackwallet.com on port 50002 via socks socket.
                        //
                        // Note that this is an SSL example.
                        await socksSocket.connectTo(
                            'bitcoin.stackwallet.com', 50002);

                        // Send a server features command to the connected socket, see method for more specific usage example..
                        await socksSocket.sendServerFeaturesCommand();

                        // You should see a server response printed to the console.
                        //
                        // Example response:
                        // `flutter: secure responseData: {
                        // 	"id": "0",
                        // 	"jsonrpc": "2.0",
                        // 	"result": {
                        // 		"cashtokens": true,
                        // 		"dsproof": true,
                        // 		"genesis_hash": "000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f",
                        // 		"hash_function": "sha256",
                        // 		"hosts": {
                        // 			"bitcoin.stackwallet.com": {
                        // 				"ssl_port": 50002,
                        // 				"tcp_port": 50001,
                        // 				"ws_port": 50003,
                        // 				"wss_port": 50004
                        // 			}
                        // 		},
                        // 		"protocol_max": "1.5",
                        // 		"protocol_min": "1.4",
                        // 		"pruning": null,
                        // 		"server_version": "Fulcrum 1.9.1"
                        // 	}
                        // }

                        // Close the socket.
                        await socksSocket.close();
                      }
                    : null,
                child: const Text(
                  "Connect to bitcoin.stackwallet.com:50002 (SSL) via socks socket",
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
