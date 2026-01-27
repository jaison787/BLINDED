import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../providers/navigation_provider.dart';
import '../camera/camera_screen.dart';
import '../settings/settings_screen.dart';
import '../tutorial/tutorial_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _requestPermissions();
    await ref.read(navigationProvider).initialize();
    setState(() {
      _isInitialized = true;
    });
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.microphone.request();
  }

  void _startNavigation() async {
    if (!_isInitialized) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CameraScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navProvider = ref.watch(navigationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Indoor Navigation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App Logo/Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.visibility_off,
                  size: 60,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Indoor Navigation',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                'AI-powered navigation assistance for visually impaired',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),

              // Status Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Icon(
                        _isInitialized ? Icons.check_circle : Icons.pending,
                        size: 48,
                        color: _isInitialized
                            ? Colors.green
                            : Theme.of(context).primaryColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        navProvider.statusMessage,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Start Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: _isInitialized && !navProvider.isInitializing
                      ? _startNavigation
                      : null,
                  child: navProvider.isInitializing
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Start Navigation'),
                ),
              ),
              const SizedBox(height: 16),

              // Tutorial Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TutorialScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: Theme.of(context).primaryColor,
                      width: 2,
                    ),
                  ),
                  child: const Text('How to Use'),
                ),
              ),

              const Spacer(),

              // Footer
              
            ],
          ),
        ),
      ),
    );
  }
}