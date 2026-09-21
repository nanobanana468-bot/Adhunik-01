import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  static Interpreter? _interpreter;

  static Future<void> initialize() async {
    try {
      _interpreter ??=
          await Interpreter.fromAsset(
        'assets/models/face_embedding.tflite',
      );
    } catch (e) {
      _interpreter = null;
      throw Exception(
        'Face recognition model could not be loaded: $e',
      );
    }
  }

  static bool get isReady {
    return _interpreter != null;
  }

  static Future<List<double>> generateEmbedding(
    Float32List input,
  ) async {
    if (_interpreter == null) {
      await initialize();
    }

    if (_interpreter == null) {
      throw Exception(
        'Face recognition is not initialized.',
      );
    }

    final output = List.generate(
      1,
      (_) => List<double>.filled(
        192,
        0.0,
      ),
    );

    _interpreter!.run(
      input,
      output,
    );

    return List<double>.from(
      output.first,
    );
  }

  static double cosineSimilarity(
    List<double> a,
    List<double> b,
  ) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) {
      return 0.0;
    }

    double dot = 0.0;
    double normA = 0.0;
    double normB = 0.0;

    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) {
      return 0.0;
    }

    return dot /
        ((normA.sqrt()) * (normB.sqrt()));
  }

  static bool isMatch(
    List<double> registeredEmbedding,
    List<double> currentEmbedding, {
    double threshold = 0.70,
  }) {
    final similarity = cosineSimilarity(
      registeredEmbedding,
      currentEmbedding,
    );

    return similarity >= threshold;
  }

  static Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
  }
}

extension on double {
  double sqrt() {
    if (this <= 0) {
      return 0.0;
    }

    double x = this;

    for (int i = 0; i < 10; i++) {
      x = 0.5 * (x + this / x);
    }

    return x;
  }
}
