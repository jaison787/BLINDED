import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';

class CameraService {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  
  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
  
  Future<void> initialize() async {
    if (_isInitialized) {
      await dispose();
    }
    try {
      _cameras = await availableCameras();
      
      if (_cameras == null || _cameras!.isEmpty) {
        throw Exception('No cameras found');
      }
      
      // Use back camera (index 0 is usually back camera)
      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );
      
      await _controller!.initialize();
      _isInitialized = true;
      
      debugPrint('Camera initialized successfully');
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      rethrow;
    }
  }
  
  Future<void> startImageStream(
    Function(CameraImage image) onImage,
  ) async {
    if (_controller == null || !_isInitialized) {
      throw Exception('Camera not initialized');
    }
    
    // Stop existing stream if any
    try {
      if (_controller!.value.isStreamingImages) {
        await _controller!.stopImageStream();
      }
    } catch (e) {
      debugPrint('Error stopping previous stream: $e');
    }
    
    await _controller!.startImageStream((image) {
      onImage(image);
    });
  }
  
  Future<void> stopImageStream() async {
    if (_controller != null && _isInitialized) {
      await _controller!.stopImageStream();
    }
  }
  
  Future<void> dispose() async {
    if (_controller != null) {
      await stopImageStream();
      await _controller!.dispose();
      _controller = null;
      _isInitialized = false;
    }
  }
  
  CameraDescription? get currentCamera => 
      _cameras != null && _cameras!.isNotEmpty ? _cameras![0] : null;
}