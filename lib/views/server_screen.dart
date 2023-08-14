import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ServerScreen extends StatefulWidget {
  const ServerScreen({super.key});

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  ServerSocket? server;
  ValueNotifier<String> messageNotifier = ValueNotifier("Loading...");
  ValueNotifier<String?> addressNotifier = ValueNotifier(null);
  ValueNotifier<int> pageNotifier = ValueNotifier(0);
  ValueNotifier<List<String>> logNotifier = ValueNotifier([]);
  PageController pageController = PageController(initialPage: 0);
  List<Socket> connectedClients = [];

  @override
  void initState() {
    NetworkInfo().getWifiIP().then((value) async {
      server = await ServerSocket.bind('0.0.0.0', 8080);
      server?.listen((Socket client) {
        handleClient(client);
      });
      messageNotifier.value = 'Server is running on $value';
      addressNotifier.value = "$value";
    });
    super.initState();
  }

  @override
  void dispose() {
    addressNotifier.dispose();
    pageNotifier.dispose();
    messageNotifier.dispose();
    pageController.dispose();
    logNotifier.dispose();
    server?.close();
    super.dispose();
  }

  void handleClient(Socket client) {
    if (connectedClients
        .where((element) => element.remoteAddress == client.remoteAddress)
        .isEmpty) {
      logNotifier.value.add("Clinet(${client.remoteAddress}) is joined");
      logNotifier.notifyListeners();
      connectedClients.add(client);
    } else {
      client.close();
    }

    client.listen(
      (data) {
        String message = utf8.decode(data);
        logNotifier.value.add('(${client.remoteAddress}): $message');
        logNotifier.notifyListeners();
        for (var element in connectedClients) {
          element.write('(${client.remoteAddress}): $message');
        }
      },
      onError: (error) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      },
      onDone: () {
        connectedClients.remove(client);
        logNotifier.value
            .add("Clinet(${client.remoteAddress}) is disconnected");
        logNotifier.notifyListeners();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Server"),
        centerTitle: true,
        bottom: AppBar(
          automaticallyImplyLeading: false,
          elevation: 3,
          title: ValueListenableBuilder(
            valueListenable: pageNotifier,
            builder: (context, value, child) => Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (value != 0) {
                        pageController.jumpToPage(0);
                        pageNotifier.value = 0;
                      }
                    },
                    child: SizedBox(
                      height: kToolbarHeight,
                      child: Center(
                        child: Text(
                          "Information",
                          style: TextStyle(
                            color: value == 0
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.5),
                            fontWeight: value == 0 ? FontWeight.w500 : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      if (value != 1) {
                        pageController.jumpToPage(1);
                        pageNotifier.value = 1;
                      }
                    },
                    child: SizedBox(
                      height: kToolbarHeight,
                      child: Center(
                        child: Text(
                          "Log",
                          style: TextStyle(
                            color: value == 1
                                ? theme.colorScheme.primary
                                : theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.5),
                            fontWeight: value == 1 ? FontWeight.w500 : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          titleTextStyle: theme.textTheme.titleMedium,
        ),
      ),
      body: PageView(
        controller: pageController,
        onPageChanged: (index) {
          pageNotifier.value = index;
        },
        children: [
          serverInformaitonPage(),
          serverLogPage(),
        ],
      ),
    );
  }

  Widget serverInformaitonPage() => Center(
        child: Builder(builder: (context) {
          return SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder(
                  valueListenable: messageNotifier,
                  builder: (context, value, child) => Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ValueListenableBuilder(
                  valueListenable: addressNotifier,
                  builder: (context, value, child) => value != null
                      ? QrImageView(
                          data: value,
                          version: QrVersions.auto,
                          size: 160,
                        )
                      : Container(
                          width: 160,
                          height: 160,
                          color: Theme.of(context)
                              .colorScheme
                              .onBackground
                              .withOpacity(0.3),
                          child: const Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Scan me to connect",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.color
                            ?.withOpacity(0.8),
                      ),
                ),
              ],
            ),
          );
        }),
      );
  Widget serverLogPage() => ValueListenableBuilder(
        valueListenable: logNotifier,
        builder: (context, logs, child) => logs.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      color:
                          Theme.of(context).iconTheme.color?.withOpacity(0.7),
                      size: 56,
                    ),
                    const SizedBox(height: 8),
                    const Text("Empty logs"),
                  ],
                ),
              )
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: logs.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) => Text(logs[index]),
                ),
              ),
      );
}
