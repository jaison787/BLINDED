import 'dart:async';
import 'dart:math';
import 'package:sensors_plus/sensors_plus.dart';

class FallDetector {
  // Tunable values
  static const double IMPACT_THRESHOLD = 25.0; // strong impact
  static const double STILLNESS_THRESHOLD = 2.0;
  static const int STILLNESS_TIME_SEC = 3;
  static const int COOLDOWN_SEC = 30;

  DateTime? _lastFallTime;
  StreamSubscription? _subscription;
  DateTime? _impactTime;

  void start({
    required void Function() onFallConfirmed,
  }) {
    _subscription = accelerometerEvents.listen((event) {
      final magnitude = sqrt(
        event.x * event.x +
        event.y * event.y +
        event.z * event.z,
      );

      // Detect impact
      if (magnitude > IMPACT_THRESHOLD) {
        _impactTime = DateTime.now();
      }

      // Check stillness after impact
      if (_impactTime != null &&
          magnitude < STILLNESS_THRESHOLD) {
        final now = DateTime.now();

        if (now.difference(_impactTime!).inSeconds >=
            STILLNESS_TIME_SEC) {
          if (_canTriggerFall(now)) {
            _lastFallTime = now;
            _impactTime = null;
            onFallConfirmed();
          }
        }
      }
    });
  }

  bool _canTriggerFall(DateTime now) {
    if (_lastFallTime == null) return true;
    return now.difference(_lastFallTime!).inSeconds > COOLDOWN_SEC;
  }

  void stop() {
    _subscription?.cancel();
  }
}
