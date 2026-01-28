import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:camera/camera.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart' as ml_kit;
import '../models/detected_object.dart';
import '../core/utils/distance_calculator.dart';
import '../core/utils/zone_analyzer.dart';

class MLKitService {
  ml_kit.ObjectDetector? _objectDetector;
  bool _isInitialized = false;
  
  // Frame skip counter to reduce processing load
  int _frameCount = 0;
  static const int _frameSkip = 1; // Process every frame for now (was 2)

  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
    // Use simpler detection first to verify pipeline works
    final options = ml_kit.ObjectDetectorOptions(
        mode: ml_kit.DetectionMode.stream,
        classifyObjects: false, // Turn off classification to rule out model download issues
        multipleObjects: true,
      );
      _objectDetector = ml_kit.ObjectDetector(options: options);
      _isInitialized = true;
      debugPrint('✅ ML Kit Service initialized (Basic Mode)');
    } catch (e) {
      debugPrint('❌ ML Kit initialization failed: $e');
      rethrow;
    }
  }

  Future<List<DetectedObject>> detectObjects(
      CameraImage image, CameraDescription camera) async {
    if (!_isInitialized || _objectDetector == null) return [];

    // Frame skip counter
    _frameCount++;
    if (_frameCount % _frameSkip != 0) return [];

    final inputImage = _inputImageFromCameraImage(image, camera);
    if (inputImage == null) return [];

    try {
      final objects = await _objectDetector!.processImage(inputImage);
      
      if (objects.isNotEmpty) {
        debugPrint('🎯 Found ${objects.length} objects!');
      }

      // Return everything found
      return objects.map((obj) {
        // Without classification, label is always empty or generic
        final label = 'Object'; 
        
        final rect = obj.boundingBox;
        // Default valid confidence if not provided
        final double confidence = 1.0; 

        // Calculate distance
        final distance = DistanceCalculator.estimateCombined(
          rect.height,
          rect.width,
          label,
          image.width.toDouble(), // Use raw image width
        );

        // Determine zone
        final zone = ZoneAnalyzer.getZone(
          rect.center.dx,
          rect.center.dy,
          image.width.toDouble(),
          image.height.toDouble(),
        );

        return DetectedObject(
          label: label,
          confidence: confidence,
          boundingBox: rect,
          distance: distance,
          zone: zone,
        );
      }).toList();
    } catch (e) {
      debugPrint('❌ Detection run error: $e');
      return [];
    }
  }

  ml_kit.InputImage? _inputImageFromCameraImage(
      CameraImage image, CameraDescription camera) {
    final sensorOrientation = camera.sensorOrientation;
    ml_kit.InputImageRotation? rotation;
    
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      rotation = ml_kit.InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      rotation = ml_kit.InputImageRotationValue.fromRawValue(sensorOrientation);
    }

    if (rotation == null) return null;

    // CRITICAL FIX: Use the actual stride from the Y plane
    final bytesPerRow = image.planes[0].bytesPerRow;
    
    // Debug print once to verify format
    if (_frameCount % 100 == 0) {
       debugPrint('Image info: ${image.width}x${image.height}, Stride: $bytesPerRow, Format: ${image.format.group}');
    }

    final bytes = _concatenatePlanes(image.planes, image.width, image.height);
    
    return ml_kit.InputImage.fromBytes(
      bytes: bytes,
      metadata: ml_kit.InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: ml_kit.InputImageFormat.nv21,
        bytesPerRow: bytesPerRow, // Pass the correct stride
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes, int width, int height) {
    final Uint8List yBytes = planes[0].bytes;
    final int ySize = yBytes.length;

    // Basic NV21 conversion
    // Basic NV21 conversion
    final int uvPixelStride = planes[1].bytesPerPixel ?? 1;
    final int uvRowStride = planes[1].bytesPerRow;
    
    if (uvPixelStride == 2) {
      final Uint8List vBytes = planes[2].bytes;
      final Uint8List res = Uint8List(ySize + vBytes.length);
      res.setRange(0, ySize, yBytes);
      res.setRange(ySize, res.length, vBytes);
      return res;
    } else {
      final Uint8List uBytes = planes[1].bytes;
      final Uint8List vBytes = planes[2].bytes;
      final Uint8List res = Uint8List(yBytes.length + uBytes.length + vBytes.length);
      res.setRange(0, yBytes.length, yBytes);
      
      int uvPos = yBytes.length;
      final int uvHeight = height ~/ 2;
      final int uvWidth = width ~/ 2;
      
      for (int row = 0; row < uvHeight; row++) {
        for (int col = 0; col < uvWidth; col++) {
          final int index = (row * uvRowStride) + (col * uvPixelStride);
          if (index < vBytes.length) res[uvPos++] = vBytes[index];
          if (index < uBytes.length) res[uvPos++] = uBytes[index];
        }
      }
      return res;
    }
  }

  void dispose() {
    _objectDetector?.close();
    _isInitialized = false;
    debugPrint('🔄 ML Kit Service disposed');
  }
}