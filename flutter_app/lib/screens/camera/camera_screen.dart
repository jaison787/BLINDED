import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:ui' as ui;
import '../../services/mlkit_service.dart';
import '../../services/detection_filter.dart';
import '../../services/camera_service.dart';
import '../../models/detected_object.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final MLKitService _mlKitService = MLKitService();
  final CameraService _cameraService = CameraService();
  
  bool _isProcessing = false;
  String _currentInstruction = 'Initializing...';
  List<DetectedObject> _detectedObjects = [];
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Initialize ML Kit
      await _mlKitService.initialize();
      
      // Initialize camera
      await _cameraService.initialize();
      
      // Start detection
      await _cameraService.startImageStream(_onCameraImage);
      
      setState(() {
        _currentInstruction = 'Ready. Point camera forward.';
      });
    } catch (e) {
      debugPrint('❌ Initialization error: $e');
      setState(() {
        _currentInstruction = 'Error: $e';
      });
    }
  }

  void _onCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    
    _isProcessing = true;

    try {
      // Store image size for scaling bounding boxes
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      
      // Detect objects
      final objects = await _mlKitService.detectObjects(
        image,
        _cameraService.currentCamera!,
      );

      // Update detected objects for drawing
      setState(() {
        _detectedObjects = objects;
      });

      // Filter and create instruction
      if (objects.isNotEmpty) {
        debugPrint('\n📊 DETECTION SUMMARY:');
        debugPrint('Total objects: ${objects.length}');
        
        final instruction = DetectionFilter.createCombinedInstruction(objects);
        
        if (instruction != null) {
          setState(() {
            _currentInstruction = instruction.message;
          });
          
          debugPrint('🗣️ Instruction: ${instruction.message}');
        }
      } else {
        setState(() {
          _currentInstruction = 'Scanning...';
        });
      }
    } catch (e) {
      debugPrint('❌ Processing error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    _mlKitService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraService.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                _currentInstruction,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Object Detection'),
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          CameraPreview(_cameraService.controller!),
          
          // Bounding box overlay
          if (_imageSize != null)
            CustomPaint(
              painter: BoundingBoxPainter(
                objects: _detectedObjects,
                imageSize: _imageSize!,
                previewSize: MediaQuery.of(context).size,
              ),
            ),
          
          // Object count badge
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.visibility, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    '${_detectedObjects.length} objects',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom instruction panel
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Detected objects list
                    if (_detectedObjects.isNotEmpty) ...[
                      const Text(
                        'DETECTED:',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _detectedObjects.take(5).map((obj) {
                          return _buildObjectChip(obj);
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Main instruction
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _getInstructionColor().withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getInstructionColor(),
                          width: 2,
                        ),
                      ),
                      child: Text(
                        _currentInstruction,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectChip(DetectedObject obj) {
    final color = _getColorForObject(obj);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIconForLabel(obj.label),
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            '${obj.label} ${obj.distance.toStringAsFixed(1)}m',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getInstructionColor() {
    if (_currentInstruction.contains('STOP') || 
        _currentInstruction.contains('STAIRS') ||
        _currentInstruction.contains('OBSTACLE')) {
      return Colors.red;
    } else if (_currentInstruction.contains('Door')) {
      return Colors.green;
    } else if (_detectedObjects.any((obj) => obj.isWarning)) {
      return Colors.orange;
    }
    return Colors.blue;
  }

  Color _getColorForObject(DetectedObject obj) {
    if (obj.isCritical) return Colors.red;
    if (obj.isWarning) return Colors.orange;
    if (obj.label == 'Door') return Colors.green;
    if (obj.label == 'Stairs') return Colors.red;
    if (obj.label == 'Person') return Colors.cyan;
    return Colors.yellow;
  }

  IconData _getIconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'door':
        return Icons.door_front_door;
      case 'stairs':
        return Icons.stairs;
      case 'person':
        return Icons.person;
      case 'chair':
        return Icons.chair;
      case 'table':
        return Icons.table_restaurant;
      case 'couch':
      case 'sofa':
        return Icons.weekend;
      case 'bed':
        return Icons.bed;
      default:
        return Icons.crop_square;
    }
  }
}

/// Custom painter to draw bounding boxes around detected objects
class BoundingBoxPainter extends CustomPainter {
  final List<DetectedObject> objects;
  final Size imageSize;
  final Size previewSize;

  BoundingBoxPainter({
    required this.objects,
    required this.imageSize,
    required this.previewSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final obj in objects) {
      final color = _getColorForObject(obj);
      
      // Scale bounding box from image coordinates to screen coordinates
      final scaleX = size.width / imageSize.width;
      final scaleY = size.height / imageSize.height;
      
      final scaledRect = Rect.fromLTRB(
        obj.boundingBox.left * scaleX,
        obj.boundingBox.top * scaleY,
        obj.boundingBox.right * scaleX,
        obj.boundingBox.bottom * scaleY,
      );

      // Draw bounding box
      final boxPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;

      // Draw rounded rectangle for the box
      canvas.drawRRect(
        RRect.fromRectAndRadius(scaledRect, const Radius.circular(8)),
        boxPaint,
      );

      // Draw corner accents (thicker lines at corners)
      final cornerLength = 20.0;
      final cornerPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.0
        ..strokeCap = StrokeCap.round;

      // Top-left corner
      canvas.drawLine(
        Offset(scaledRect.left, scaledRect.top + cornerLength),
        Offset(scaledRect.left, scaledRect.top),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(scaledRect.left, scaledRect.top),
        Offset(scaledRect.left + cornerLength, scaledRect.top),
        cornerPaint,
      );

      // Top-right corner
      canvas.drawLine(
        Offset(scaledRect.right - cornerLength, scaledRect.top),
        Offset(scaledRect.right, scaledRect.top),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(scaledRect.right, scaledRect.top),
        Offset(scaledRect.right, scaledRect.top + cornerLength),
        cornerPaint,
      );

      // Bottom-left corner
      canvas.drawLine(
        Offset(scaledRect.left, scaledRect.bottom - cornerLength),
        Offset(scaledRect.left, scaledRect.bottom),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(scaledRect.left, scaledRect.bottom),
        Offset(scaledRect.left + cornerLength, scaledRect.bottom),
        cornerPaint,
      );

      // Bottom-right corner
      canvas.drawLine(
        Offset(scaledRect.right - cornerLength, scaledRect.bottom),
        Offset(scaledRect.right, scaledRect.bottom),
        cornerPaint,
      );
      canvas.drawLine(
        Offset(scaledRect.right, scaledRect.bottom),
        Offset(scaledRect.right, scaledRect.bottom - cornerLength),
        cornerPaint,
      );

      // Draw label background
      final labelText = '${obj.label} ${(obj.confidence * 100).toInt()}%';
      final textSpan = TextSpan(
        text: labelText,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 2,
            ),
          ],
        ),
      );
      
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();

      // Label background
      final labelBgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          scaledRect.left,
          scaledRect.top - textPainter.height - 8,
          textPainter.width + 16,
          textPainter.height + 8,
        ),
        const Radius.circular(6),
      );

      final labelBgPaint = Paint()
        ..color = color.withOpacity(0.85)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(labelBgRect, labelBgPaint);

      // Draw label text
      textPainter.paint(
        canvas,
        Offset(scaledRect.left + 8, scaledRect.top - textPainter.height - 4),
      );

      // Draw distance badge
      final distanceText = '${obj.distance.toStringAsFixed(1)}m';
      final distanceSpan = TextSpan(
        text: distanceText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      
      final distancePainter = TextPainter(
        text: distanceSpan,
        textDirection: ui.TextDirection.ltr,
      );
      distancePainter.layout();

      // Distance background (bottom right of box)
      final distanceBgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          scaledRect.right - distancePainter.width - 12,
          scaledRect.bottom + 4,
          distancePainter.width + 12,
          distancePainter.height + 6,
        ),
        const Radius.circular(4),
      );

      final distanceBgPaint = Paint()
        ..color = Colors.black.withOpacity(0.7)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(distanceBgRect, distanceBgPaint);

      distancePainter.paint(
        canvas,
        Offset(
          scaledRect.right - distancePainter.width - 6,
          scaledRect.bottom + 7,
        ),
      );
    }
  }

  Color _getColorForObject(DetectedObject obj) {
    if (obj.isCritical) return Colors.red;
    if (obj.isWarning) return Colors.orange;
    if (obj.label == 'Door') return Colors.green;
    if (obj.label == 'Stairs') return Colors.red;
    if (obj.label == 'Person') return Colors.cyan;
    return Colors.yellow;
  }

  @override
  bool shouldRepaint(BoundingBoxPainter oldDelegate) {
    return objects != oldDelegate.objects;
  }
}
