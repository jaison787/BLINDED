import 'package:flutter/material.dart';
import 'services/sms_service.dart';

void main() {
  runApp(const IndoorNavApp());
}

class IndoorNavApp extends StatelessWidget {
  const IndoorNavApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sms = SmsService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('SMS Test'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            bool success = true;

            try {
              await sms.sendSms(
                "+918078923590", // 👈 replace with your number
                "TEST: SmsManager working",
              );
            } catch (e) {
              success = false;
            }

            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(success ? 'SMS Sent!' : 'SMS Failed'),
                backgroundColor:
                    success ? Colors.green : Colors.red,
              ),
            );
          },
          child: const Text('SEND TEST SMS'),
        ),
      ),
    );
  }
}
