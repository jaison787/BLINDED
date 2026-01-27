import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart'
    as ml_kit;
import '../models/detected_object.dart';
import '../core/utils/distance_calculator.dart';
import '../core/utils/zone_analyzer.dart';

class MLKitService {
  ml_kit.ObjectDetector? _objectDetector;
  bool _isInitialized = false;

  Future<void> initialize() async {
    final options = ml_kit.ObjectDetectorOptions(
      mode: ml_kit.DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ml_kit.ObjectDetector(options: options);
    _isInitialized = true;
  }

  Future<List<DetectedObject>> detectObjects(
      CameraImage image, CameraDescription camera) async {
    if (!_isInitialized || _objectDetector == null) return [];

    final inputImage = _inputImageFromCameraImage(image, camera);
    if (inputImage == null) return [];

    try {
      final objects = await _objectDetector!.processImage(inputImage);
      if (objects.isNotEmpty) {
        debugPrint('ML Kit found ${objects.length} raw objects');
      }

      return objects.map((obj) {
        final rect = obj.boundingBox;
        
        // ML Kit sometimes returns empty labels or generic ones
        String label = (obj.labels.isNotEmpty && obj.labels.first.text.isNotEmpty) 
            ? obj.labels.first.text 
            : 'Obstacle';
            
        final confidence =
            obj.labels.isNotEmpty ? obj.labels.first.confidence : 0.0;

        // Calculate rotation-aware dimensions once
        final isRotated = inputImage.metadata!.rotation == ml_kit.InputImageRotation.rotation90deg ||
                          inputImage.metadata!.rotation == ml_kit.InputImageRotation.rotation270deg;
        
        // Use image dimensions for distance and metadata size for zone mapping
        final double distEffectiveWidth = isRotated ? image.height.toDouble() : image.width.toDouble();
        final double zoneEffectiveWidth = isRotated ? inputImage.metadata!.size.height : inputImage.metadata!.size.width;
        final double zoneEffectiveHeight = isRotated ? inputImage.metadata!.size.width : inputImage.metadata!.size.height;

        // Heuristic for door detection
        final double aspectRatio = rect.height / rect.width;
        // Doors are usually tall and narrow
        final String lowLabel = label.toLowerCase();
        if (label == 'Obstacle' || label == 'Home good' || label == 'Place' || label == 'Object' || 
            lowLabel.contains('furniture') || lowLabel.contains('structure') || lowLabel.contains('wall')) {
          if (aspectRatio > 1.1 && aspectRatio < 5.0) {
            // Check if it's large enough to be a door (at least 25% of height)
            if (rect.height > zoneEffectiveHeight * 0.25) {
              label = 'Door';
            }
          }
        }
        
        // Heuristic for stairs detection
        if (label == 'Obstacle' || label == 'Home good' || label == 'Furniture' || label == 'Object') {
           if (rect.width > rect.height * 1.2 && rect.bottom > zoneEffectiveHeight * 0.5) {
             label = 'Stairs/Step';
           }
        }

        // Calculate distance
        final distance = DistanceCalculator.estimateCombined(
          rect.height,
          rect.width,
          label,
          distEffectiveWidth,
        );

        // Determine zone
        final zone = ZoneAnalyzer.getZone(
          rect.center.dx,
          rect.center.dy,
          zoneEffectiveWidth,
          zoneEffectiveHeight,
        );
        
        debugPrint('Detected: $label at ${distance.toStringAsFixed(1)}m, position: $zone');

        return DetectedObject(
          label: label,
          confidence: confidence,
          boundingBox: rect,
          distance: distance,
          zone: zone,
        );
      }).toList();
    } catch (e) {
      debugPrint('Error detecting objects: $e');
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
      // For MVP, just using sensor orientation directly
      rotation = ml_kit.InputImageRotationValue.fromRawValue(sensorOrientation);
    }

    final rotation = ml_kit.InputImageRotationValue.fromRawValue(camera.sensorOrientation) ?? 
                    ml_kit.InputImageRotation.rotation90deg;

    final bytes = _concatenatePlanes(image.planes, image.width, image.height);
    
    return ml_kit.InputImage.fromBytes(
      bytes: bytes,
      metadata: ml_kit.InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: ml_kit.InputImageFormat.nv21,
        bytesPerRow: image.width, // NV21 stride is usually just width
      ),
    );
  }

  Uint8List _concatenatePlanes(List<Plane> planes, int width, int height) {
    if (planes.length == 1) return planes[0].bytes;

    final Uint8List yBytes = planes[0].bytes;
    final Uint8List uBytes = planes[1].bytes;
    final Uint8List vBytes = planes[2].bytes;

    // NV21 is Y + V + U interleaved.
    // Total size = Y size + U size + V size
    final Uint8List res = Uint8List(yBytes.length + uBytes.length + vBytes.length);
    res.setRange(0, yBytes.length, yBytes);

    final int uvPixelStride = planes[1].bytesPerPixel ?? 1;
    final int uvRowStride = planes[1].bytesPerRow;
    
    // For NV21 we want Y then V then U interleaved.
    // If uvPixelStride is 2, the planes are already semi-planar (V then U or U then V).
    if (uvPixelStride == 2) {
      // On most Androids, the V plane already contains interleaved V and U.
      // We can just append the V plane bytes.
      final Uint8List vBytes = planes[2].bytes;
      final Uint8List res = Uint8List(yBytes.length + vBytes.length);
      res.setRange(0, yBytes.length, yBytes);
      res.setRange(yBytes.length, res.length, vBytes);
      return res;
    } else {
      // Planar format: manual interleaving
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
  }
}
