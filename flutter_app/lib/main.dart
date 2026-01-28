import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';

import 'services/sms_service.dart';

void main() {
  runApp(const BlindedApp());
}

class BlindedApp extends StatelessWidget {
  const BlindedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: SafetyScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  final SmsService sms = SmsService();

  StreamSubscription? _accelSub;
  StreamSubscription? _gyroSub;

  double _gyroMag = 0.0;
  DateTime? _impactTime;
  DateTime? _lastAlertTime;

  // ===== TUNABLE VALUES =====
  static const double ACC_IMPACT_THRESHOLD = 2.0;
  static const double GYRO_THRESHOLD = 2.5;
  static const double STILLNESS_THRESHOLD = 2.0;

  static const int STILLNESS_SECONDS = 2;
  static const int COOLDOWN_SECONDS = 10;

  final List<String> emergencyContacts = [
    "+919994235648", // replace
  ];

  @override
  void initState() {
    super.initState();
    _startSensors();
  }

  // ===== SENSOR FUSION =====
  void _startSensors() {
    _gyroSub = gyroscopeEvents.listen((g) {
      _gyroMag = sqrt(g.x * g.x + g.y * g.y + g.z * g.z);
    });

    _accelSub = accelerometerEvents.listen((a) async {
      final accMag = sqrt(a.x * a.x + a.y * a.y + a.z * a.z);

      if (accMag > ACC_IMPACT_THRESHOLD && _gyroMag > GYRO_THRESHOLD) {
        _impactTime = DateTime.now();
      }

      if (_impactTime != null && accMag < STILLNESS_THRESHOLD) {
        final now = DateTime.now();

        if (now.difference(_impactTime!).inSeconds >= STILLNESS_SECONDS &&
            _canSendAlert(now)) {
          _impactTime = null;
          _lastAlertTime = now;
          await _sendEmergencySms(reason: "Fall detected");
        }
      }
    });
  }

  bool _canSendAlert(DateTime now) {
    if (_lastAlertTime == null) return true;
    return now.difference(_lastAlertTime!).inSeconds > COOLDOWN_SECONDS;
  }

  // ===== GPS SAFE (NEVER BLOCKS SMS) =====
  Future<String> _getLocationLinkSafe() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(const Duration(seconds: 5));

      return "https://maps.google.com/?q=${pos.latitude},${pos.longitude}";
    } catch (_) {
      return "Location unavailable";
    }
  }

  // ===== EMERGENCY SMS (SMS FIRST, GPS AFTER) =====
  Future<void> _sendEmergencySms({required String reason}) async {
    debugPrint(">>> EMERGENCY SMS FUNCTION CALLED <<<");

    // 1️⃣ SEND SMS IMMEDIATELY
    final firstMsg =
        "🚨 EMERGENCY ALERT\n"
        "$reason.\n"
        "Location: fetching...";

    for (final n in emergencyContacts) {
      await sms.sendSms(n, firstMsg);
      await Future.delayed(const Duration(seconds: 2));
    }

    // 2️⃣ TRY GPS AND SEND UPDATE
    final locationLink = await _getLocationLinkSafe();

    final secondMsg =
        "📍 LOCATION UPDATE\n"
        "$locationLink";

    for (final n in emergencyContacts) {
      await sms.sendSms(n, secondMsg);
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

  // ===== MANUAL SOS =====
  void _manualSOS() async {
    if (_canSendAlert(DateTime.now())) {
      _lastAlertTime = DateTime.now();
      await _sendEmergencySms(reason: "Manual SOS triggered");
    }
  }

  @override
  void dispose() {
    _accelSub?.cancel();
    _gyroSub?.cancel();
    super.dispose();
  }

  // ===== UI =====
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("BLINDED – Safety Active"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Fall detection is ACTIVE",
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 20,
                ),
              ),
              onPressed: _manualSOS,
              child: const Text(
                "SOS",
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
