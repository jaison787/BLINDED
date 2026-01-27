import 'package:flutter_tts/flutter_tts.dart';
import '../models/navigation_instruction.dart';

class TTSService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  DateTime? _lastSpokenTime;
  // Minimum interval between repeated similar messages
  final Duration _repetitionInterval = const Duration(seconds: 3);

  Future<void> initialize() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // Handle completion
    _flutterTts.setCompletionHandler(() {
      _isSpeaking = false;
    });
  }

  Future<void> speak(NavigationInstruction instruction) async {
    // Priority handling
    if (_isSpeaking) {
      if (instruction.priority == InstructionPriority.critical) {
        await _flutterTts.stop();
      } else {
        // Skip lower priority if speaking
        return;
      }
    }

    // Debounce similar low-priority messages
    if (instruction.priority == InstructionPriority.info ||
        instruction.priority == InstructionPriority.low) {
      if (_lastSpokenTime != null &&
          DateTime.now().difference(_lastSpokenTime!) < _repetitionInterval) {
        return;
      }
    }

    _isSpeaking = true;
    _lastSpokenTime = DateTime.now();
    await _flutterTts.speak(instruction.message);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
    _isSpeaking = false;
  }

  Future<void> announceDetections(List<String> announcements) async {
    if (announcements.isEmpty) return;
    final message = announcements.join(", ");
    await speak(NavigationInstruction(
      message: message,
      priority: InstructionPriority.medium,
      direction: Direction.forward,
    ));
  }

  void dispose() {
    _flutterTts.stop();
  }
}
