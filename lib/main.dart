import 'package:flutter/material.dart';

void main() {
  runApp(const SonoraApp());
}

class SonoraApp extends StatelessWidget {
  const SonoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SONORA',
      theme: ThemeData.dark(),
      home: const Scaffold(
        body: Center(
          child: Text('SONORA Music Service'),
        ),
      ),
    );
  }
}