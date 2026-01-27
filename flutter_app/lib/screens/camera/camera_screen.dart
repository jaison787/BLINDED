import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../../providers/navigation_provider.dart';
import 'widgets/detection_overlay.dart';
import 'widgets/audio_indicator.dart';

class CameraScreen extends ConsumerStatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends ConsumerState<CameraScreen> {
  bool _isStarted = false;

  @override
  void initState() {
    super.initState();
    // Auto-start navigation when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNavigation();
    });
  }

  Future<void> _startNavigation() async {
    debugPrint('[CameraScreen] Starting navigation...');
    try {
      await ref.read(navigationProvider).startNavigation();
      if (mounted) {
        setState(() {
          _isStarted = true;
        });
      }
      debugPrint('[CameraScreen] Navigation started successfully');
    } catch (e) {
      debugPrint('[CameraScreen] Failed to start navigation: $e');
    }
  }

  Future<void> _stopNavigation() async {
    await ref.read(navigationProvider).stopNavigation();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = ref.watch(navigationProvider);
    final cameraController = navProvider.cameraService.controller;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _stopNavigation();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Camera Preview
            if (cameraController != null &&
                cameraController.value.isInitialized)
              Center(
                child: CameraPreview(cameraController),
              )
            else if (navProvider.statusMessage.contains('failed'))
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error, color: Colors.red, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      navProvider.statusMessage,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _startNavigation,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else
              const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Initializing camera...',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),

            // Detection Overlay
            if (_isStarted && navProvider.detectedObjects.isNotEmpty)
              DetectionOverlay(
                objects: navProvider.detectedObjects,
                imageSize: navProvider.lastImageSize,
              ),

            // Audio Indicator
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: AudioIndicator(
                instruction: navProvider.currentInstruction,
              ),
            ),

            // Control Panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Object Count
                    if (navProvider.detectedObjects.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${navProvider.detectedObjects.length} object${navProvider.detectedObjects.length > 1 ? 's' : ''} detected',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Stop Button
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _stopNavigation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text(
                          'Stop Navigation',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Status overlay (top)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: navProvider.isNavigating
                            ? Colors.green
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      navProvider.isNavigating ? 'Navigating' : 'Stopped',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (_isStarted) {
      ref.read(navigationProvider).stopNavigation();
    }
    super.dispose();
  }
}
