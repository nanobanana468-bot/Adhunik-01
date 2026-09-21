import 'dart:io';

import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceService {
  static final FaceDetector _faceDetector =
      FaceDetector(
    options: FaceDetectorOptions(
      enableClassification: true,
      enableLandmarks: true,
      enableContours: true,
      enableTracking: true,
      performanceMode:
          FaceDetectorMode.accurate,
    ),
  );

  static Future<List<Face>> detectFaces(
    String imagePath,
  ) async {
    final inputImage =
        InputImage.fromFile(File(imagePath));

    final faces =
        await _faceDetector.processImage(
      inputImage,
    );

    return faces;
  }

  static Future<bool> hasSingleFace(
    String imagePath,
  ) async {
    try {
      final faces =
          await detectFaces(imagePath);

      return faces.length == 1;
    } catch (_) {
      return false;
    }
  }

  static Future<String> validateFace(
    String imagePath,
  ) async {
    try {
      final faces =
          await detectFaces(imagePath);

      if (faces.isEmpty) {
        return 'No face detected. Please capture the photo again.';
      }

      if (faces.length > 1) {
        return 'Multiple faces detected. Please capture only one employee.';
      }

      final face = faces.first;

      final width = face.boundingBox.width;
      final height = face.boundingBox.height;

      if (width < 80 || height < 80) {
        return 'Face is too far away. Please move closer to the camera.';
      }

      return 'OK';
    } catch (e) {
      return 'Face detection failed: $e';
    }
  }

  static Future<void> dispose() async {
    await _faceDetector.close();
  }
}
