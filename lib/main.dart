import 'package:flutter/material.dart';

import 'screens/punching_screen.dart';
import 'services/camera_service.dart';
import 'services/database_service.dart';
import 'services/face_recognition_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Camera initialize
  await CameraService.initialize();

  // Local database initialize
  await DatabaseService.database;

  // Face recognition model initialize
  // If model has an issue, app will still open.
  try {
    await FaceRecognitionService.initialize();
  } catch (e) {
    debugPrint(
      'Face recognition model initialization failed: $e',
    );
  }

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
        colorSchemeSeed: Colors.blue,
        scaffoldBackgroundColor:
            const Color(0xFFF5F7FA),
      ),
      home: const PunchingScreen(),
    );
  }
}
