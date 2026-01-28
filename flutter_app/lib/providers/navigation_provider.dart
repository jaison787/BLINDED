import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../models/detected_object.dart';
import '../models/navigation_instruction.dart';
import '../services/camera_service.dart';
import '../services/mlkit_service.dart';
import '../services/tts_service.dart';
import '../services/haptic_service.dart';
import '../controllers/navigation_controller.dart';

final navigationProvider =
    ChangeNotifierProvider<NavigationProvider>((ref) => NavigationProvider());

class NavigationProvider extends ChangeNotifier {
  // Services
  final CameraService _cameraService = CameraService();
  final MLKitService _mlKitService = MLKitService();
  final TTSService _ttsService = TTSService();
  final HapticService _hapticService = HapticService();
  final NavigationController _navigationController = NavigationController();

  // State
  bool _isNavigating = false;
  bool _isInitializing = false;
  bool _initialized = false;
  bool _isProcessing = false;
  List<DetectedObject> _detectedObjects = [];
  NavigationInstruction? _currentInstruction;
  String _statusMessage = 'Ready to start';
  bool _disposed = false;
  Size? _lastImageSize;

  // Getters
  bool get isNavigating => _isNavigating;
  bool get isInitializing => _isInitializing;
  List<DetectedObject> get detectedObjects => _detectedObjects;
  NavigationInstruction? get currentInstruction => _currentInstruction;
  String get statusMessage => _statusMessage;
  CameraService get cameraService => _cameraService;
  Size? get lastImageSize => _lastImageSize;

  // Initialize all services
  Future<void> initialize() async {
    if (_initialized || _isInitializing) return;

    _isInitializing = true;
    _setStatus('Initializing services...');
    notifyListeners();

    try {
      await _cameraService.initialize();
      await _mlKitService.initialize();
      await _ttsService.initialize();
      await _hapticService.initialize();

      _initialized = true;
      _setStatus('Ready to start navigation');
      _isInitializing = false;
      notifyListeners();
    } catch (e) {
      _setStatus('Initialization failed: $e');
      _isInitializing = false;
      notifyListeners();
      rethrow;
    }
  }

  // Start navigation
  Future<void> startNavigation() async {
    if (_isNavigating) return;

    try {
      _isNavigating = true;
      _setStatus('Navigation started');
      notifyListeners();

      await _ttsService.speak(NavigationInstruction(
        message: "Navigation started",
        priority: InstructionPriority.info,
        direction: Direction.forward,
      ));

      // Start processing camera stream
      await _cameraService.startImageStream(_processCameraImage);
    } catch (e) {
      _setStatus('Failed to start navigation: $e');
      _isNavigating = false;
      notifyListeners();
    }
  }

  // Stop navigation
  Future<void> stopNavigation() async {
    if (!_isNavigating) return;

    try {
      await _cameraService.stopImageStream();
      await _ttsService.stop();
      await _hapticService.cancel();

      _isNavigating = false;
      _detectedObjects = [];
      _currentInstruction = null;
      _setStatus('Navigation stopped');
      notifyListeners();

      await _ttsService.speak(NavigationInstruction(
        message: "Navigation stopped",
        priority: InstructionPriority.info,
        direction: Direction.stop,
      ));
    } catch (e) {
      debugPrint('Error stopping navigation: $e');
    }
  }

  // Process camera image
  Future<void> _processCameraImage(CameraImage image) async {
    if (!_isNavigating || _isProcessing) return;

    try {
      _isProcessing = true;
      final camera = _cameraService.currentCamera;
      if (camera == null) {
        _isProcessing = false;
        return;
      }

      // Detect objects
      final objects = await _mlKitService.detectObjects(image, camera);
      _lastImageSize = Size(image.width.toDouble(), image.height.toDouble());
      _detectedObjects = objects;

      // Analyze and generate navigation instruction
      if (objects.isNotEmpty) {
        // Sort by distance to show the closest on screen
        objects.sort((a, b) => a.distance.compareTo(b.distance));
        final closest = objects.first;
        
        final instruction = _navigationController.analyzeAndNavigate(
          objects,
          image.width.toDouble(),
          image.height.toDouble(),
        );

        _currentInstruction = instruction;
        
        // Update status for visual feedback
        _statusMessage = "${instruction.message}\n(Sees ${objects.length} objects)";

        // Provide audio feedback (debounced in TTSService)
        await _ttsService.speak(instruction);

        // Provide haptic feedback if needed
        if (instruction.requiresVibration) {
          await _hapticService.vibrate(instruction.priority);
        }
      } else {
        // No objects detected
        _currentInstruction = NavigationInstruction(
          message: "Scanning area...",
          priority: InstructionPriority.low,
          direction: Direction.forward,
        );
        _statusMessage = "Scanning... (Searching for objects)";
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  @override
  void notifyListeners() {
    if (_disposed) return;
    super.notifyListeners();
  }

  void _setStatus(String message) {
    _statusMessage = message;
    debugPrint('Status: $message');
  }

  @override
  void dispose() {
    _disposed = true;
    _cameraService.dispose();
    _mlKitService.dispose();
    _ttsService.dispose();
    super.dispose();
  }
}
