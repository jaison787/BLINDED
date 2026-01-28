import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'services/sms_service.dart';

void main() {
  runApp(const BlindedApp());
}

class BlindedApp extends StatelessWidget {
  const BlindedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: FallDetectionScreen(),
    );
  }
}

class FallDetectionScreen extends StatefulWidget {
  const FallDetectionScreen({super.key});

  @override
  State<FallDetectionScreen> createState() => _FallDetectionScreenState();
}

class _FallDetectionScreenState extends State<FallDetectionScreen> {
  final SmsService sms = SmsService();

  StreamSubscription? _accelSub;
  DateTime? _lastFallTime;
  DateTime? _impactTime;

  // ---- TUNABLE VALUES ----
  static const double IMPACT_THRESHOLD = 12.0;
  static const double STILLNESS_THRESHOLD = 2.0;
  static const int STILLNESS_SECONDS = 3;
  static const int COOLDOWN_SECONDS = 3;

  @override
  void initState() {
    super.initState();
    _startFallDetection();
  }

  void _startFallDetection() {
    _accelSub = accelerometerEvents.listen((event) async {
      final magnitude = sqrt(
        event.x * event.x +
        event.y * event.y +
        event.z * event.z,
      );

      // Detect impact
      if (magnitude > IMPACT_THRESHOLD) {
        _impactTime = DateTime.now();
      }

      // Detect stillness after impact
      if (_impactTime != null && magnitude < STILLNESS_THRESHOLD) {
        final now = DateTime.now();

        if (now.difference(_impactTime!).inSeconds >= STILLNESS_SECONDS) {
          if (_canSendAlert(now)) {
            _lastFallTime = now;
            _impactTime = null;

            await _sendEmergencySms();
          }
        }
      }
    });
  }

  bool _canSendAlert(DateTime now) {
    if (_lastFallTime == null) return true;
    return now.difference(_lastFallTime!).inSeconds > COOLDOWN_SECONDS;
  }

  Future<void> _sendEmergencySms() async {
    const message =
        "🚨 EMERGENCY ALERT\nFall detected.\nPlease check immediately.";

    const contacts = [
      "+918078923590", // replace
      "+917012966766", // replace
    ];

    for (final number in contacts) {
      await sms.sendSms(number, message);
      await Future.delayed(const Duration(seconds: 2));
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Emergency SMS sent"),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BLINDED – Fall Detection"),
      ),
      body: const Center(
        child: Text(
          "Fall detection is ACTIVE",
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
