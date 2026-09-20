import 'package:flutter/material.dart';

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
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ADHUNIK.01'),
        ),
        body: const Center(
          child: Text(
            'ADHUNIK.01',
            style: TextStyle(fontSize: 28),
          ),
        ),
      ),
    );
  }
}
