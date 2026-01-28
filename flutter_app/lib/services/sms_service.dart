import 'package:flutter/services.dart';

class SmsService {
  static const MethodChannel _channel =
      MethodChannel('emergency_sms');

  Future<void> sendSms(String number, String message) async {
    await _channel.invokeMethod('sendSms', {
      'number': number,
      'message': message,
    });
  }
}
