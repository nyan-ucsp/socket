import 'package:flutter/material.dart';
import 'package:sync_x/views/client_screen.dart';
import 'package:sync_x/views/server_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "Socket test on ",
                      style: theme.textTheme.titleLarge,
                    ),
                    TextSpan(
                      text: "dart:io",
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                "Run your device as",
                style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ServerScreen(),
                    ),
                  );
                },
                child: const Text("Server"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const ClientScreen(),
                    ),
                  );
                },
                child: const Text("Client"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
