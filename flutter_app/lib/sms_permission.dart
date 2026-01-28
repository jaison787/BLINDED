import 'package:flutter/services.dart';

class SmsPermission {
  static const _channel = MethodChannel('emergency_sms');

  static Future<bool> request() async {
    try {
      final bool granted =
          await _channel.invokeMethod('requestSmsPermission');
      return granted;
    } catch (_) {
      return false;
    }
  }
}
