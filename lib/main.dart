import 'package:flutter/material.dart';
import 'screens/punching_screen.dart';
import 'services/camera_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await CameraService.initialize();

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
