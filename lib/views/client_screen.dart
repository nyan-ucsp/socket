import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_dart_scan/qr_code_dart_scan.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  ValueNotifier<Socket?> socketNotifier = ValueNotifier(null);
  ValueNotifier<String?> serverAddressNotifier = ValueNotifier(null);
  ValueNotifier<List<String>> logNotifier = ValueNotifier([]);
  ValueNotifier<int> pageNotifier = ValueNotifier(0);
  ValueNotifier<bool> scanQRNotifier = ValueNotifier(false);
  PageController pageController = PageController(initialPage: 0);
  TextEditingController messageController = TextEditingController();
  @override
  void dispose() {
    super.dispose();
    socketNotifier.dispose();
    serverAddressNotifier.dispose();
    logNotifier.dispose();
    pageController.dispose();
    scanQRNotifier.dispose();
    messageController.dispose();
  }

  Future<bool> connectToServer() async {
    if (socketNotifier.value == null && serverAddressNotifier.value != null) {
      Socket socket = await Socket.connect(serverAddressNotifier.value, 8080);
      logNotifier.value
          .add('Connected to Socket Server (${serverAddressNotifier.value})');
      logNotifier.notifyListeners();
      socketNotifier.value = socket;
      socket.listen(
        (data) {
          String message = utf8.decode(data);
          logNotifier.value.add(message);
          logNotifier.notifyListeners();
        },
        onError: (error) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.toString())));
        },
        onDone: () {
          socketNotifier.value = null;
        },
      );
      return true;
    } else {
      return false;
    }
  }

  void sendMessage(String message) {
    socketNotifier.value?.write(message);
    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Client"),
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
          clientInformaitonPage(),
          clientLogPage(),
        ],
      ),
    );
  }

  Widget clientInformaitonPage() => Center(
        child: Builder(builder: (context) {
          final theme = Theme.of(context);
          return ValueListenableBuilder(
            valueListenable: socketNotifier,
            builder: (context, socket, child) => socket != null
                ? SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Colors.red,
                          size: 56,
                        ),
                        ValueListenableBuilder(
                          valueListenable: serverAddressNotifier,
                          builder: (context, serverAddress, child) => RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "Socket is connected to ",
                                  style: theme.textTheme.bodyLarge,
                                ),
                                TextSpan(
                                  text: serverAddress,
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            await socket.close();
                            socketNotifier.value = null;
                            serverAddressNotifier.value = null;
                          },
                          child: const Text("Disconnect"),
                        )
                      ],
                    ),
                  )
                : ValueListenableBuilder(
                    valueListenable: scanQRNotifier,
                    builder: (context, isScan, child) => isScan
                        ? Column(
                            children: [
                              Expanded(
                                child: QRCodeDartScanView(
                                  scanInvertedQRCode: true,
                                  typeScan: TypeScan.live,
                                  formats: const [BarcodeFormat.QR_CODE],
                                  onCapture: (Result result) {
                                    if (result.text.trim().isNotEmpty) {
                                      serverAddressNotifier.value = result.text;
                                      connectToServer();
                                      scanQRNotifier.value = false;
                                      scanQRNotifier.notifyListeners();
                                    }
                                  },
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      scanQRNotifier.value = false;
                                    },
                                    icon: const Icon(
                                        Icons.qr_code_scanner_outlined),
                                    label: const Text("Close QR Scan"),
                                  )
                                ],
                              )
                            ],
                          )
                        : SingleChildScrollView(
                            child: Column(
                              children: [
                                Icon(
                                  Icons.heart_broken,
                                  color:
                                      theme.iconTheme.color?.withOpacity(0.7),
                                  size: 56,
                                ),
                                Text(
                                  "Socket server not connected",
                                  style: theme.textTheme.bodyLarge
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: () {
                                    scanQRNotifier.value = true;
                                  },
                                  child: const Text("Try Connect"),
                                )
                              ],
                            ),
                          ),
                  ),
          );
        }),
      );

  Widget clientLogPage() => ValueListenableBuilder(
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
            : Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: logs.length,
                        shrinkWrap: true,
                        itemBuilder: (context, index) => Text(logs[index]),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom + 4,
                    ),
                    child: SizedBox(
                      child: Row(
                        children: [
                          Flexible(
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8),
                              child: TextField(
                                controller: messageController,
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderSide: BorderSide.none,
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  filled: true,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: IconButton(
                              onPressed: () {
                                if (messageController.text.trim().isNotEmpty) {
                                  sendMessage(messageController.text);
                                }
                              },
                              icon: Icon(
                                Icons.send,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      );
}
