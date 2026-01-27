import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../services/object_detector_service.dart';
import '../services/tts_service.dart';

class DetectionScreen extends StatefulWidget {
  final CameraDescription camera;

  const DetectionScreen({super.key, required this.camera});

  @override
  State<DetectionScreen> createState() => _DetectionScreenState();
}

class _DetectionScreenState extends State<DetectionScreen> {
  late CameraController _cameraController;
  final ObjectDetectorService _detector = ObjectDetectorService();
  final TTSService _tts = TTSService();

  bool _isInitialized = false;
  bool _isDetecting = false;
  bool _isProcessing = false;
  List<DetectionResult> _detections = [];
  String _statusMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      setState(() => _statusMessage = 'Loading camera...');

      // Initialize camera
      _cameraController = CameraController(
        widget.camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      await _cameraController.initialize();

      setState(() => _statusMessage = 'Loading AI model...');

      // Initialize detector
      await _detector.initialize();

      // Initialize TTS
      await _tts.initialize();

      setState(() {
        _isInitialized = true;
        _statusMessage = 'Ready! Tap Start to begin detection';
      });

      // Welcome message
      await _tts.speak('SANSA Navigation ready. Tap the start button to begin obstacle detection.');
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
      print('[DetectionScreen] Initialization error: $e');
    }
  }

  void _startDetection() {
    if (!_isInitialized || _isDetecting) return;

    setState(() {
      _isDetecting = true;
      _statusMessage = 'Detecting obstacles...';
    });

    _tts.speak('Detection started');

    _cameraController.startImageStream((image) async {
      if (!_isProcessing && _isDetecting) {
        _isProcessing = true;

        try {
          final results = await _detector.processFrame(image);

          if (mounted) {
            setState(() => _detections = results);

            // Announce detections via TTS
            if (results.isNotEmpty) {
              final announcements = results
                  .take(3)
                  .map((r) => '${r.label} on ${r.position}')
                  .toList();
              await _tts.announceDetections(announcements);
            }
          }
        } catch (e) {
          print('[DetectionScreen] Detection error: $e');
        }

        _isProcessing = false;
      }
    });
  }

  void _stopDetection() {
    if (!_isDetecting) return;

    _cameraController.stopImageStream();
    _tts.speak('Detection stopped');

    setState(() {
      _isDetecting = false;
      _detections = [];
      _statusMessage = 'Detection paused. Tap Start to resume.';
    });
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _detector.dispose();
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),

            // Camera Preview with Detections
            Expanded(
              child: _isInitialized
                  ? _buildCameraPreview()
                  : _buildLoadingView(),
            ),

            // Detection Results
            if (_detections.isNotEmpty) _buildDetectionList(),

            // Control Buttons
            _buildControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C63FF).withOpacity(0.8),
            const Color(0xFF4834D4).withOpacity(0.8),
          ],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.visibility, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'SANSA Navigation',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isDetecting ? Colors.green : Colors.grey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _isDetecting ? 'ACTIVE' : 'PAUSED',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Color(0xFF6C63FF),
            strokeWidth: 3,
          ),
          const SizedBox(height: 24),
          Text(
            _statusMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Camera Preview
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CameraPreview(_cameraController),
        ),

        // Detection Overlays
        CustomPaint(
          painter: DetectionPainter(
            detections: _detections,
            previewSize: _cameraController.value.previewSize ?? const Size(640, 480),
          ),
        ),

        // Status Overlay
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _statusMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetectionList() {
    return Container(
      height: 100,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _detections.length,
        itemBuilder: (context, index) {
          final detection = _detections[index];
          return Container(
            width: 120,
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6C63FF).withOpacity(0.7),
                  const Color(0xFF4834D4).withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  detection.label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  detection.position.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.amber.shade300,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(detection.confidence * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Start/Stop Button
          GestureDetector(
            onTap: _isInitialized
                ? (_isDetecting ? _stopDetection : _startDetection)
                : null,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isDetecting
                      ? [Colors.red.shade600, Colors.red.shade800]
                      : [const Color(0xFF6C63FF), const Color(0xFF4834D4)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isDetecting ? Colors.red : const Color(0xFF6C63FF))
                        .withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _isDetecting ? Icons.stop : Icons.play_arrow,
                color: Colors.white,
                size: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for drawing detection bounding boxes
class DetectionPainter extends CustomPainter {
  final List<DetectionResult> detections;
  final Size previewSize;

  DetectionPainter({required this.detections, required this.previewSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (final detection in detections) {
      // Scale bounding box to canvas size
      final scaleX = size.width / previewSize.height; // Rotated
      final scaleY = size.height / previewSize.width;

      final rect = Rect.fromLTRB(
        detection.boundingBox.left * scaleX,
        detection.boundingBox.top * scaleY,
        detection.boundingBox.right * scaleX,
        detection.boundingBox.bottom * scaleY,
      );

      // Color based on position
      paint.color = detection.position == 'center'
          ? Colors.red
          : detection.position == 'left'
              ? Colors.orange
              : Colors.yellow;

      canvas.drawRect(rect, paint);

      // Draw label
      textPainter.text = TextSpan(
        text: '${detection.label} (${detection.position})',
        style: TextStyle(
          color: paint.color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.black54,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(rect.left, rect.top - 20));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
