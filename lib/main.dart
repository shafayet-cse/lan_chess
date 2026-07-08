import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const LanChessApp());
}

class LanChessApp extends StatelessWidget {
  const LanChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LAN Chess',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF769656),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
      home: const HomeScreen(),
    );
  }
}
