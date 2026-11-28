import 'package:flutter/material.dart';
import 'package:sonora/core/themes/app_theme.dart';
import 'package:sonora/presentation/screens/home/home_screen.dart';

void main() {
  runApp(const SonoraApp());
}

class SonoraApp extends StatelessWidget {
  const SonoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SONORA',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}