import 'dart:typed_data';
import 'dart:math' as math;

import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  static Interpreter? _interpreter;

  static Future<void> initialize() async {
    if (_interpreter != null) {
      return;
    }

    try {
      _interpreter = await Interpreter.fromAsset(
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

  static List<int> get inputShape {
    if (_interpreter == null) {
      throw Exception(
        'Face recognition is not initialized.',
      );
    }

    return _interpreter!.getInputTensor(0).shape;
  }

  static List<int> get outputShape {
    if (_interpreter == null) {
      throw Exception(
        'Face recognition is not initialized.',
      );
    }

    return _interpreter!.getOutputTensor(0).shape;
  }

  static Future<List<double>> generateEmbedding(
    Float32List input,
  ) async {
    await initialize();

    final interpreter = _interpreter;

    if (interpreter == null) {
      throw Exception(
        'Face recognition is not initialized.',
      );
    }

    final outputTensor =
        interpreter.getOutputTensor(0);

    final outputShape = outputTensor.shape;

    final embeddingSize =
        outputShape.isNotEmpty
            ? outputShape.last
            : 192;

    final output = List.generate(
      1,
      (_) => List<double>.filled(
        embeddingSize,
        0.0,
      ),
    );

    interpreter.run(
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
    if (a.isEmpty ||
        b.isEmpty ||
        a.length != b.length) {
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

    if (normA == 0.0 || normB == 0.0) {
      return 0.0;
    }

    return dot /
        (math.sqrt(normA) * math.sqrt(normB));
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
