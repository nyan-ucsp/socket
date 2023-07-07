import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late String deviceIP, otherDeviceIp;
  ValueNotifier<String> valueNotifier = ValueNotifier("Loading...");
  ValueNotifier<bool?> serverStartNotifier = ValueNotifier(false);
  ServerSocket? server;
  @override
  void initState() {
    NetworkInfo().getWifiIP().then((value) {
      deviceIP = value ?? "";
      valueNotifier.value = "Device IP : ${value ?? "No IP Address Available"}";
      otherDeviceIp =
          value == "192.168.100.141" ? "192.168.100.108" : "192.168.100.141";
    });

    super.initState();
  }

  void handleClient(Socket client) {
    debugPrint(
        'Client connected: ${client.remoteAddress.address}:${client.remotePort}');

    // Handle data received from the client
    client.listen((List<int> data) {
      String message = utf8.decode(data);
      debugPrint('Received data from client: $message');

      // Echo the message back to the client
      client.write('Server Received: $message');
    }, onError: (error) {
      debugPrint('Error: $error');
    }, onDone: () {
    });
  }

  void sayHiToServer() async {
    try {
      // Connect to the server
      final socket = await Socket.connect(otherDeviceIp, 8080);
      debugPrint('Connected to the server');
      // Send data to the server
      String message = 'Say Hi From, $deviceIP!';
      socket.write(utf8.encode(message));

      // Receive data from the server
      socket.listen((List<int> data) {
        String response = utf8.decode(data);
        debugPrint('Received data from server: $response');
      }, onError: (error) {
        debugPrint('Error: $error');
        socket.destroy();
      }, onDone: () {
        debugPrint('Server disconnected');
        socket.destroy();
      });

      // Close the socket connection
      socket.close();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ValueListenableBuilder(
              valueListenable: valueNotifier,
              builder: (context, value, child) => Text(value),
            ),
            const SizedBox(height: 32),
            ValueListenableBuilder(
              valueListenable: serverStartNotifier,
              builder: (context, value, child) => ElevatedButton(
                onPressed: value == null
                    ? null
                    : () async {
                        if (value) {
                          serverStartNotifier.value = null;
                          await server?.close();
                          debugPrint(
                              'Server on ${server?.address.address}:${server?.port} closed');
                          serverStartNotifier.value = false;
                        } else {
                          serverStartNotifier.value = null;

                          server = await ServerSocket.bind('0.0.0.0', 8080);
                          debugPrint(
                              'Server started on ${server?.address.address}:${server?.port}');

                          server?.listen((Socket client) {
                            handleClient(client);
                          });
                          serverStartNotifier.value = true;
                        }
                      },
                child: Text(
                  value == null
                      ? "Loading..."
                      : value
                          ? "Stop Server"
                          : "Start Server",
                ),
              ),
            ),
            ElevatedButton(onPressed: (){
              sayHiToServer();
            }, child: const Text("Say Hi"),)
          ],
        ),
      ),
    );
  }
}
