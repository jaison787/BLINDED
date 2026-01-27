import 'package:flutter/material.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How to Use'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Introduction Card
          _buildCard(
            context,
            icon: Icons.info,
            title: 'Welcome',
            content:
                'This app helps visually impaired users navigate indoor spaces safely using AI-powered object detection and voice guidance.',
            color: Colors.blue,
          ),
          const SizedBox(height: 16),

          // Getting Started
          _buildCard(
            context,
            icon: Icons.play_circle,
            title: 'Getting Started',
            content: '1. Grant camera and microphone permissions\n'
                '2. Hold your phone in front of you at chest level\n'
                '3. Press "Start Navigation" button\n'
                '4. Listen to voice instructions',
            color: Colors.green,
          ),
          const SizedBox(height: 16),

          // Audio Instructions
          _buildCard(
            context,
            icon: Icons.volume_up,
            title: 'Audio Instructions',
            content: 'The app will announce:\n\n'
                '• Objects detected ahead\n'
                '• Direction to turn (left/right)\n'
                '• Distance to obstacles\n'
                '• Warnings for nearby objects\n'
                '• Critical alerts for immediate danger',
            color: Colors.purple,
          ),
          const SizedBox(height: 16),

          // Understanding Alerts
          _buildCard(
            context,
            icon: Icons.warning,
            title: 'Alert Levels',
            content: '🟢 Safe - Path is clear\n\n'
                '🟡 Caution - Object nearby (1-3m)\n\n'
                '🟠 Warning - Object close (0.5-1m)\n\n'
                '🔴 Critical - Stop immediately (<0.5m)',
            color: Colors.orange,
          ),
          const SizedBox(height: 16),

          // Haptic Feedback
          _buildCard(
            context,
            icon: Icons.vibration,
            title: 'Haptic Feedback',
            content: 'Your phone will vibrate for:\n\n'
                '• Strong obstacles directly ahead\n'
                '• Critical danger situations\n'
                '• Important navigation changes\n\n'
                'You can disable this in Settings.',
            color: Colors.red,
          ),
          const SizedBox(height: 16),

          // Tips Card
          _buildCard(
            context,
            icon: Icons.lightbulb,
            title: 'Tips for Best Results',
            content: '✓ Use in well-lit environments\n'
                '✓ Walk slowly and steadily\n'
                '✓ Keep phone stable\n'
                '✓ Use headphones for clearer audio\n'
                '✓ Familiarize yourself with the space first\n'
                '✓ Have a companion for initial use',
            color: Colors.amber,
          ),
          const SizedBox(height: 16),

          // Safety Warning
          _buildCard(
            context,
            icon: Icons.health_and_safety,
            title: 'Important Safety Notice',
            content:
                '⚠️ This app is an assistive tool, not a replacement for:\n\n'
                '• White canes\n'
                '• Guide dogs\n'
                '• Human assistance\n'
                '• Personal judgment\n\n'
                'Always use multiple navigation aids and exercise caution.',
            color: Colors.red[900]!,
          ),
          const SizedBox(height: 16),

          // Limitations
          _buildCard(
            context,
            icon: Icons.error_outline,
            title: 'Known Limitations',
            content: '• May not detect small objects on the floor\n'
                '• Performance affected by lighting\n'
                '• Cannot detect overhead obstacles\n'
                '• May have delays in crowded areas\n'
                '• Does not provide turn-by-turn directions',
            color: Colors.grey[700]!,
          ),
          const SizedBox(height: 24),

          // Support Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () {
                _showSupportDialog(context);
              },
              icon: const Icon(Icons.support_agent),
              label: const Text('Need Help?'),
            ),
          ),
          const SizedBox(height: 16),

          // Test Navigation Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.navigation),
              label: const Text('Start Navigation'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String content,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support'),
        content: const Text(
          'For assistance with this app:\n\n'
          '• Review this tutorial again\n'
          '• Check app settings\n'
          '• Contact: Fidha Gafoor\n'
          '• Institution: Holygrace Academy of Engineering\n'
          '• Project: OCIUZ Skills Academy',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
