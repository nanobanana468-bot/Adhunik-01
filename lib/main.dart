import 'package:flutter/material.dart';
import 'screens/punching_screen.dart';

void main() {
  runApp(const AdhunikApp());
}

class AdhunikApp extends StatelessWidget {
  const AdhunikApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ADHUNIK.01',
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const PunchingScreen(),
    );
  }
}
