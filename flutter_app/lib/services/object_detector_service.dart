import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:tflite_flutter_plus/tflite_flutter_plus.dart';
import 'package:camera/camera.dart';
import 'dart:math';

/// Detection result model
class DetectionResult {
  final String label;
  final double confidence;
  final Rect boundingBox;
  final String position; // "left", "center", "right"

  DetectionResult({
    required this.label,
    required this.confidence,
    required this.boundingBox,
    required this.position,
  });

  @override
  String toString() =>
      '$label (${(confidence * 100).toStringAsFixed(0)}%) - $position';
}

/// YOLOv8 Object Detector Service
class ObjectDetectorService {
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;

  static const int inputSize = 320;
  static const double confidenceThreshold = 0.5;
  static const double iouThreshold = 0.4;

  bool get isInitialized => _isInitialized;

  /// Initialize the detector with model and labels
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load the TFLite model
      _interpreter = await Interpreter.fromAsset(
        'assets/models/yolov8n_float32.tflite',
      );

      // Load labels
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n').where((l) => l.trim().isNotEmpty).toList();

      _isInitialized = true;
      print('[Detector] Initialized with ${_labels.length} labels');
    } catch (e) {
      print('[Detector] Initialization failed: $e');
      rethrow;
    }
  }

  /// Process a camera frame and return detections
  Future<List<DetectionResult>> processFrame(CameraImage image) async {
    if (!_isInitialized || _interpreter == null) {
      return [];
    }

    try {
      // Convert YUV to RGB and resize
      final input = _preprocessImage(image);

      // Prepare output tensor
      // YOLOv8 output shape: [1, 84, 8400] for 80 classes
      final output = List.generate(
        1,
        (_) => List.generate(84, (_) => List.filled(8400, 0.0)),
      );

      // Run inference
      _interpreter!.run(input, output);

      // Post-process results
      return _postProcess(output[0], image.width, image.height);
    } catch (e) {
      print('[Detector] Processing error: $e');
      return [];
    }
  }

  /// Preprocess image: YUV to RGB, resize to inputSize x inputSize
  List<List<List<List<double>>>> _preprocessImage(CameraImage image) {
    // Create input tensor [1, 320, 320, 3]
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (_) => List.generate(inputSize, (_) => List.filled(3, 0.0)),
      ),
    );

    // Simple YUV420 to RGB conversion
    final int uvRowStride = image.planes[1].bytesPerRow;
    final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    for (int y = 0; y < inputSize; y++) {
      for (int x = 0; x < inputSize; x++) {
        // Map to original image coordinates
        final int srcX = (x * image.width / inputSize).floor();
        final int srcY = (y * image.height / inputSize).floor();

        // Get Y value
        final int yIndex = srcY * image.planes[0].bytesPerRow + srcX;
        final int yValue = image.planes[0].bytes[yIndex];

        // Get UV values
        final int uvIndex = (srcY ~/ 2) * uvRowStride + (srcX ~/ 2) * uvPixelStride;
        final int uValue = image.planes[1].bytes[uvIndex];
        final int vValue = image.planes[2].bytes[uvIndex];

        // YUV to RGB conversion
        int r = (yValue + 1.402 * (vValue - 128)).round().clamp(0, 255);
        int g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
            .round()
            .clamp(0, 255);
        int b = (yValue + 1.772 * (uValue - 128)).round().clamp(0, 255);

        // Normalize to [0, 1]
        input[0][y][x][0] = r / 255.0;
        input[0][y][x][1] = g / 255.0;
        input[0][y][x][2] = b / 255.0;
      }
    }

    return input;
  }

  /// Post-process YOLOv8 output to get detection results
  List<DetectionResult> _postProcess(
    List<List<double>> output,
    int imageWidth,
    int imageHeight,
  ) {
    final List<DetectionResult> results = [];

    // YOLOv8 output: [84, 8400] where 84 = 4 (bbox) + 80 (classes)
    final int numDetections = output[0].length; // 8400

    for (int i = 0; i < numDetections; i++) {
      // Get bounding box (center_x, center_y, width, height)
      final double cx = output[0][i];
      final double cy = output[1][i];
      final double w = output[2][i];
      final double h = output[3][i];

      // Find the class with maximum confidence
      double maxConf = 0.0;
      int maxClassIdx = 0;
      for (int c = 0; c < 80; c++) {
        final conf = output[4 + c][i];
        if (conf > maxConf) {
          maxConf = conf;
          maxClassIdx = c;
        }
      }

      // Filter by confidence
      if (maxConf >= confidenceThreshold) {
        // Convert to pixel coordinates
        final double left = (cx - w / 2) * imageWidth / inputSize;
        final double top = (cy - h / 2) * imageHeight / inputSize;
        final double right = (cx + w / 2) * imageWidth / inputSize;
        final double bottom = (cy + h / 2) * imageHeight / inputSize;

        // Determine position (left, center, right)
        final centerX = (left + right) / 2;
        String position;
        if (centerX < imageWidth / 3) {
          position = "left";
        } else if (centerX > imageWidth * 2 / 3) {
          position = "right";
        } else {
          position = "center";
        }

        results.add(DetectionResult(
          label: maxClassIdx < _labels.length ? _labels[maxClassIdx] : 'unknown',
          confidence: maxConf,
          boundingBox: Rect.fromLTRB(left, top, right, bottom),
          position: position,
        ));
      }
    }

    // Apply Non-Maximum Suppression
    return _nms(results);
  }

  /// Non-Maximum Suppression to remove overlapping boxes
  List<DetectionResult> _nms(List<DetectionResult> detections) {
    if (detections.isEmpty) return [];

    // Sort by confidence
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    final List<DetectionResult> result = [];
    final List<bool> suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      result.add(detections[i]);

      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        if (_iou(detections[i].boundingBox, detections[j].boundingBox) > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return result;
  }

  /// Calculate Intersection over Union
  double _iou(Rect a, Rect b) {
    final intersect = a.intersect(b);
    if (intersect.isEmpty) return 0.0;

    final intersectArea = intersect.width * intersect.height;
    final unionArea = a.width * a.height + b.width * b.height - intersectArea;

    return intersectArea / unionArea;
  }

  /// Dispose resources
  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}
