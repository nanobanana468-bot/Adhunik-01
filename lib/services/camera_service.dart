import 'package:camera/camera.dart';

class CameraService {
  static List<CameraDescription> cameras = [];

  static Future<void> initialize() async {
    try {
      cameras = await availableCameras();
    } catch (e) {
      cameras = [];
    }
  }

  static CameraDescription? get frontCamera {
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.front) {
        return camera;
      }
    }
    return cameras.isNotEmpty ? cameras.first : null;
  }

  static CameraDescription? get backCamera {
    for (final camera in cameras) {
      if (camera.lensDirection == CameraLensDirection.back) {
        return camera;
      }
    }
    return cameras.isNotEmpty ? cameras.first : null;
  }
}
