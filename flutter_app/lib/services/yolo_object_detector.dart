import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter_vision/flutter_vision.dart';

/// Service class for YOLOv8 object detection using a TFLite model.
///
/// This class wraps the functionality provided by the `flutter_vision`
/// package. It loads the quantized TFLite model and the corresponding
/// `labels.txt` file from the app's assets, then provides a method to
/// process a camera frame and return detection results.
class YoloObjectDetector {
  /// The FlutterVision instance from the flutter_vision package.
  late FlutterVision _vision;

  /// Flag to ensure the model is loaded only once.
  bool _initialized = false;

  /// Check if the detector has been initialized.
  bool get isInitialized => _initialized;

  /// Initializes the detector by loading the TFLite model and the label file.
  ///
  /// The model file should be placed at `assets/models/yolov8n_int8.tflite`
  /// and the label file at `assets/models/labels.txt`. Both paths must be
  /// declared under the `assets:` section of `pubspec.yaml`.
  ///
  /// Parameters:
  /// - [modelPath]: Path to the TFLite model file (default: 'assets/models/yolov8n_int8.tflite')
  /// - [labelsPath]: Path to the labels file (default: 'assets/models/labels.txt')
  /// - [numThreads]: Number of threads for inference (default: 4)
  /// - [useGpu]: Whether to use GPU acceleration (default: false for INT8 models)
  Future<void> initialize({
    String modelPath = 'assets/models/yolov8n_int8.tflite',
    String labelsPath = 'assets/models/labels.txt',
    int numThreads = 4,
    bool useGpu = false,
  }) async {
    if (_initialized) return;

    _vision = FlutterVision();

    // Load the YOLO model with specified configuration
    await _vision.loadYoloModel(
      modelPath: modelPath,
      labels: labelsPath,
      modelVersion: 'yolov8',
      quantization: true, // INT8 quantized model
      numThreads: numThreads,
      useGpu: useGpu,
    );

    _initialized = true;
  }

  /// Processes a single camera frame and returns detection results.
  ///
  /// The `CameraImage` provided by the `camera` plugin is in YUV420 format.
  /// The `flutter_vision` package's `yoloOnFrame` method handles the
  /// YUV-to-RGB conversion internally.
  ///
  /// Parameters:
  /// - [image]: The CameraImage from the camera stream
  /// - [confidenceThreshold]: Minimum confidence for detections (default: 0.5)
  /// - [iouThreshold]: IoU threshold for NMS (default: 0.4)
  ///
  /// Returns a list of [DetectionResult] objects containing the bounding box,
  /// class label, and confidence score.
  Future<List<DetectionResult>> processFrame(
    CameraImage image, {
    double confidenceThreshold = 0.5,
    double iouThreshold = 0.4,
  }) async {
    if (!_initialized) {
      throw StateError(
        'YoloObjectDetector not initialized. Call initialize() first.',
      );
    }

    // Use flutter_vision's yoloOnFrame which handles YUV420 input
    final List<Map<String, dynamic>> results = await _vision.yoloOnFrame(
      bytesList: image.planes.map((plane) => plane.bytes).toList(),
      imageHeight: image.height,
      imageWidth: image.width,
      iouThreshold: iouThreshold,
      confThreshold: confidenceThreshold,
      classThreshold: confidenceThreshold,
    );

    // Convert raw results to DetectionResult objects
    return results.map((result) {
      final box = result['box'] as List<dynamic>;
      return DetectionResult(
        label: result['tag'] as String,
        confidence: (result['box'][4] as num).toDouble(),
        boundingBox: Rect.fromLTWH(
          (box[0] as num).toDouble(),
          (box[1] as num).toDouble(),
          (box[2] as num).toDouble(),
          (box[3] as num).toDouble(),
        ),
      );
    }).toList();
  }

  /// Releases resources used by the detector.
  ///
  /// Call this method when the detector is no longer needed.
  Future<void> dispose() async {
    if (_initialized) {
      await _vision.closeYoloModel();
      _initialized = false;
    }
  }
}

/// Model for a single detection result.
class DetectionResult {
  /// The detected object's class label (e.g., "person", "car").
  final String label;

  /// Confidence score of the detection (0.0 to 1.0).
  final double confidence;

  /// Bounding box of the detected object in image coordinates.
  final Rect boundingBox;

  DetectionResult({
    required this.label,
    required this.confidence,
    required this.boundingBox,
  });

  @override
  String toString() {
    return 'DetectionResult(label: $label, confidence: ${confidence.toStringAsFixed(2)}, box: $boundingBox)';
  }
}
