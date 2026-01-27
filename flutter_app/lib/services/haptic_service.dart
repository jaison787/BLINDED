import 'package:vibration/vibration.dart';
import '../models/navigation_instruction.dart';

class HapticService {
  bool _isEnabled = true;
  
  bool get isEnabled => _isEnabled;
  
  Future<void> initialize() async {
    // Check if device supports vibration
    final hasVibrator = await Vibration.hasVibrator();
    _isEnabled = hasVibrator ?? false;
  }
  
  Future<void> vibrate(InstructionPriority priority) async {
    if (!_isEnabled) return;
    
    switch (priority) {
      case InstructionPriority.critical:
        // Strong, repeated vibration for critical alerts
        await _criticalVibration();
        break;
      case InstructionPriority.high:
        // Medium vibration for warnings
        await Vibration.vibrate(duration: 500);
        break;
      case InstructionPriority.medium:
        // Light vibration for medium priority
        await Vibration.vibrate(duration: 200);
        break;
      case InstructionPriority.low:
      case InstructionPriority.info:
        // No vibration for low priority
        break;
    }
  }
  
  Future<void> _criticalVibration() async {
    // Pattern: vibrate-pause-vibrate-pause-vibrate
    await Vibration.vibrate(duration: 300);
    await Future.delayed(const Duration(milliseconds: 100));
    await Vibration.vibrate(duration: 300);
    await Future.delayed(const Duration(milliseconds: 100));
    await Vibration.vibrate(duration: 300);
  }
  
  Future<void> successVibration() async {
    if (!_isEnabled) return;
    await Vibration.vibrate(duration: 100);
  }
  
  void setEnabled(bool enabled) {
    _isEnabled = enabled;
  }
  
  Future<void> cancel() async {
    if (_isEnabled) {
      await Vibration.cancel();
    }
  }
}
