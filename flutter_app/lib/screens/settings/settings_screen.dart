import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _speechRate = 0.5;
  double _detectionSensitivity = 0.5;
  bool _hapticFeedback = true;
  bool _continuousAnnouncement = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _speechRate = prefs.getDouble('speech_rate') ?? 0.5;
      _detectionSensitivity = prefs.getDouble('detection_sensitivity') ?? 0.5;
      _hapticFeedback = prefs.getBool('haptic_feedback') ?? true;
      _continuousAnnouncement = prefs.getBool('continuous_announcement') ?? false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is double) {
      await prefs.setDouble(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Speech Settings Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.volume_up, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Speech Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Speech Rate
                  Text(
                    'Speech Rate: ${_speechRate.toStringAsFixed(1)}x',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Slider(
                    value: _speechRate,
                    min: 0.3,
                    max: 1.0,
                    divisions: 7,
                    label: '${_speechRate.toStringAsFixed(1)}x',
                    onChanged: (value) {
                      setState(() {
                        _speechRate = value;
                      });
                      _saveSetting('speech_rate', value);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Continuous Announcement
                  SwitchListTile(
                    title: const Text('Continuous Announcements'),
                    subtitle: const Text('Announce obstacles repeatedly'),
                    value: _continuousAnnouncement,
                    onChanged: (value) {
                      setState(() {
                        _continuousAnnouncement = value;
                      });
                      _saveSetting('continuous_announcement', value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Detection Settings Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.visibility, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Detection Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Detection Sensitivity
                  Text(
                    'Detection Sensitivity: ${(_detectionSensitivity * 100).toInt()}%',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Slider(
                    value: _detectionSensitivity,
                    min: 0.3,
                    max: 0.9,
                    divisions: 6,
                    label: '${(_detectionSensitivity * 100).toInt()}%',
                    onChanged: (value) {
                      setState(() {
                        _detectionSensitivity = value;
                      });
                      _saveSetting('detection_sensitivity', value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Feedback Settings Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.vibration, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Feedback Settings',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Haptic Feedback
                  SwitchListTile(
                    title: const Text('Haptic Feedback'),
                    subtitle: const Text('Vibrate on obstacle detection'),
                    value: _hapticFeedback,
                    onChanged: (value) {
                      setState(() {
                        _hapticFeedback = value;
                      });
                      _saveSetting('haptic_feedback', value);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // About Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'About',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Indoor Navigation for Visually Impaired',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('Version 1.0.0'),
                  const SizedBox(height: 8),
                  const Text('Developed by Fidha Gafoor'),
                  const SizedBox(height: 4),
                  const Text('Holygrace Academy of Engineering'),
                  const SizedBox(height: 4),
                  const Text('OCIUZ Skills Academy Project'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Reset Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _resetSettings,
              icon: const Icon(Icons.refresh),
              label: const Text('Reset to Defaults'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetSettings() async {
    setState(() {
      _speechRate = 0.5;
      _detectionSensitivity = 0.5;
      _hapticFeedback = true;
      _continuousAnnouncement = false;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings reset to defaults'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
