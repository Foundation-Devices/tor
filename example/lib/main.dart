// Example app deps, not necessarily needed for tor usage.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
// Imports needed for tor usage:
import 'package:socks5_proxy/socks_client.dart'; // Just for example; can use any socks5 proxy package, pick your favorite.
import 'package:socks_socket/socks_socket.dart';
import 'package:tor_ffi_plugin/tor_ffi_plugin.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Home());
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _MyAppState();
}

class _MyAppState extends State<Home> {
  // Flag to track if tor has started.
  bool torIsRunning = false;

  // Set the default text for the host input field.
  final hostController = TextEditingController(text: 'https://icanhazip.com/');
  // https://check.torproject.org is another good option.

  // Set the default text for the onion input field.
  final onionController = TextEditingController(
    text: 'https://cflarexljc3rw355ysrkrzwapozws6nre6xsy3n4yrj7taye3uiby3ad.onion',
  );
  // See https://blog.cloudflare.com/cloudflare-onion-service/ for more options:
  // cflarexljc3rw355ysrkrzwapozws6nre6xsy3n4yrj7taye3uiby3ad.onion
  // cflarenuttlfuyn7imozr4atzvfbiw3ezgbdjdldmdx7srterayaozid.onion
  // cflares35lvdlczhy3r6qbza5jjxbcplzvdveabhf7bsp7y4nzmn67yd.onion
  // cflareusni3s7vwhq2f7gc4opsik7aa4t2ajedhzr42ez6uajaywh3qd.onion
  // cflareki4v3lh674hq55k3n7xd4ibkwx3pnw67rr3gkpsonjmxbktxyd.onion
  // cflarejlah424meosswvaeqzb54rtdetr4xva6mq2bm2hfcx5isaglid.onion
  // cflaresuje2rb7w2u3w43pn4luxdi6o7oatv6r2zrfb5xvsugj35d2qd.onion
  // cflareer7qekzp3zeyqvcfktxfrmncse4ilc7trbf6bp6yzdabxuload.onion
  // cflareub6dtu7nvs3kqmoigcjdwap2azrkx5zohb2yk7gqjkwoyotwqd.onion
  // cflare2nge4h4yqr3574crrd7k66lil3torzbisz6uciyuzqc2h2ykyd.onion

  final bitcoinOnionController = TextEditingController(
    text:
        'qly7g5n5t3f3h23xvbp44vs6vpmayurno4basuu5rcvrupli7y2jmgid.onion:50001',
  );
  // For more options, see https://bitnodes.io/nodes/addresses/?q=onion and
  // https://sethforprivacy.com/about/

  final moneroOnionController = TextEditingController(
    text: 'ucdouiihzwvb5edg3ezeufcs4yp26gq4x64n6b4kuffb7s7jxynnk7qd.onion:18081/json_rpc',
  );

  @override
  void initState() {
    super.initState();
    unawaited(init());
  }

  Future<void> init() async {
    // Start the Tor daemon.
    await Tor.instance.start(
      torDataDirPath: (await getApplicationSupportDirectory()).path,
    );

    // Toggle started flag.
    setState(() {
      torIsRunning = Tor.instance.status == TorStatus.on; // Update flag
    });

    debugPrint('Done awaiting; tor should be running');
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    hostController.dispose();
    onionController.dispose();
    super.dispose();
  }

  Future<void> startTor() async {
    // Start the Tor daemon.
    await Tor.instance.start(
      torDataDirPath: (await getApplicationSupportDirectory()).path,
    );

    // Toggle started flag.
    setState(() {
      torIsRunning = Tor.instance.status == TorStatus.on; // Update flag
    });

    debugPrint('Done awaiting; tor should be running');
  }

  Future<void> testMoneroOnionNodeConnection() async {
    try {
      // Validate the onion address.
      if (!moneroOnionController.text.contains(".onion")) {
        debugPrint("Invalid onion address");
        return;
      } else if (!moneroOnionController.text.contains(":")) {
        debugPrint("Invalid onion address (needs port)");
        return;
      }

      final String host = moneroOnionController.text.split(":").first;
      final int port = int.parse(
        moneroOnionController.text.split(":").last.split("/").first,
      );
      final String path = moneroOnionController.text
          .split(":")
          .last
          .split("/")
          .last; // Extract the path

      var socksSocket = await SOCKSSocket.create(
        proxyHost: InternetAddress.loopbackIPv4.address,
        proxyPort: Tor.instance.port,
        sslEnabled: false,
      );

      await socksSocket.connect();
      await socksSocket.connectTo(host, port);

      final body = jsonEncode({
        "jsonrpc": "2.0",
        "id": "0",
        "method": "get_info",
      });

      final request =
          'POST /$path HTTP/1.1\r\n'
          'Host: $host\r\n'
          'Content-Type: application/json\r\n'
          'Content-Length: ${body.length}\r\n'
          '\r\n'
          '$body';

      socksSocket.write(request);
      debugPrint("Request sent: $request");

      await for (var response in socksSocket.inputStream) {
        final result = utf8.decode(response);
        debugPrint("Response received: $result");
        break;
      }

      await socksSocket.close();
    } catch (e, s) {
      debugPrint("Error connecting to Monero onion node: $e\n$s");
    }
  }

  @override
  Widget build(BuildContext context) {
    const spacerSmall = SizedBox(height: 10);
    return Scaffold(
      appBar: AppBar(title: const Text('Tor example')),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              Row(
                children: [
                  TextButton(
                    onPressed: torIsRunning
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

                            debugPrint("NOW: $time");

                            await startTor();

                            debugPrint(
                              "Start tor took "
                              "${DateTime.now().difference(time).inSeconds} "
                              "seconds",
                            );

                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                    child: const Text("Start tor"),
                  ),
                  TextButton(
                    onPressed: !torIsRunning
                        ? null
                        : () async {
                            await Tor.instance.disable();
                            setState(() {
                              torIsRunning = false;
                            });
                          },
                    child: const Text("Stop tor"),
                  ),
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
                  // Proxied HTTP request button.
                  TextButton(
                    onPressed: torIsRunning
                        ? () async {
                            // `socks5_proxy` package example, use another socks5
                            // connection of your choice.

                            // Create HttpClient object
                            final client = HttpClient();

                            // Assign connection factory.
                            SocksTCPClient.assignToHttpClient(client, [
                              ProxySettings(
                                InternetAddress.loopbackIPv4,
                                Tor.instance.port,
                                password: null,
                              ), // TODO get from tor's config file.
                            ]);

                            // GET request.
                            final request = await client.getUrl(
                              Uri.parse(hostController.text),
                            );
                            final response = await request.close();

                            // Print response.
                            var responseString = await utf8.decodeStream(
                              response,
                            );
                            debugPrint(responseString);
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
                onPressed: torIsRunning
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
                          'bitcoin.stackwallet.com',
                          50002,
                        );

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
              spacerSmall,
              Row(
                children: [
                  // Bitcoin onion input field.
                  Expanded(
                    child: TextField(
                      controller: bitcoinOnionController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Bitcoin onion address to test',
                      ),
                    ),
                  ),
                  spacerSmall,
                  TextButton(
                    onPressed: torIsRunning
                        ? () async {
                            // Validate the onion address.www
                            if (!onionController.text.contains(".onion")) {
                              debugPrint("Invalid onion address");
                              return;
                            } else if (!onionController.text.contains(":")) {
                              debugPrint("Invalid onion address (needs port)");
                              return;
                            }

                            String domain = bitcoinOnionController.text
                                .split(":")
                                .first;
                            int port = int.parse(
                              bitcoinOnionController.text.split(":").last,
                            );

                            // Instantiate a socks socket at localhost and on the port selected by the tor service.
                            var socksSocket = await SOCKSSocket.create(
                              proxyHost: InternetAddress.loopbackIPv4.address,
                              proxyPort: Tor.instance.port,
                              sslEnabled: !domain.endsWith(
                                ".onion",
                              ), // For SSL connections.
                            );

                            // Connect to the socks instantiated above.
                            await socksSocket.connect();

                            // Connect to onion node via socks socket.
                            //
                            // Note that this is an SSL example.
                            await socksSocket.connectTo(domain, port);

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
                        // A mutex should be added to this example to prevent
                        // multiple connections from being made at once.  TODO
                        : null,
                    child: const Text("Test Bitcoin onion node connection"),
                  ),
                ],
              ),
              spacerSmall,
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: moneroOnionController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Monero onion address to test',
                      ),
                    ),
                  ),
                  spacerSmall,
                  TextButton(
                    onPressed: torIsRunning
                        ? testMoneroOnionNodeConnection
                        : null,
                    child: const Text("Test Monero onion node connection"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
