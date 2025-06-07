import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart'; // Update with the actual path to your AuthService
import 'login_screen.dart'; // Update with the actual path to your LoginScreen
import 'register_screen.dart'; // Update with the actual path to your RegisterScreen
import 'map_screen.dart'; // Update with the actual path to your MapScreen
import 'converter_screen.dart'; // Update with the actual path to your ConverterScreen
import 'profile_screen.dart'; // Update with the actual path to your ProfileScreen
import '../services/pedometer_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _localProfilePhotoBase64;

  @override
  void initState() {
    super.initState();
    _loadLocalProfilePhoto();
  }

  Future<void> _loadLocalProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _localProfilePhotoBase64 = prefs.getString('profile_photo_base64');
    });
  }

  void _onProfilePhotoUpdated() {
    _loadLocalProfilePhoto();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final pedometerService = PedometerService();
        pedometerService.start();
        return pedometerService;
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('NomadDaily')),
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Welcome to NomadDaily!',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your daily companion for remote work and travel.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                Consumer<PedometerService>(
                  builder: (context, pedometer, _) {
                    return Column(
                      children: [
                        const Text(
                          'Steps today:',
                          style: TextStyle(fontSize: 16),
                        ),
                        Text(
                          pedometer.steps.toString(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
                // Show user info if logged in
                Builder(
                  builder: (context) {
                    final user = Provider.of<AuthService>(context).user;
                    if (user == null) {
                      return Column(
                        children: [
                          const Text(
                            'Not signed in',
                            style: TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            child: const Text('Sign In'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              );
                            },
                            child: const Text(
                              "Don't have an account? Register",
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        if (_localProfilePhotoBase64 != null)
                          CircleAvatar(
                            radius: 32,
                            backgroundImage: MemoryImage(
                              base64Decode(_localProfilePhotoBase64!),
                            ),
                          )
                        else if (user.photoUrl != null &&
                            user.photoUrl!.isNotEmpty)
                          CircleAvatar(
                            radius: 32,
                            backgroundImage: NetworkImage(user.photoUrl!),
                          )
                        else
                          const CircleAvatar(
                            radius: 32,
                            child: Icon(Icons.person, size: 32),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          user.name != null && user.name!.isNotEmpty
                              ? user.name!
                              : 'No Name',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(user.email.isNotEmpty ? user.email : 'No Email'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: 0, // Home is index 0
          onTap: (index) {
            if (index == 1) {
              Navigator.of(
                context,
              ).pushReplacement(MaterialPageRoute(builder: (_) => MapScreen()));
            } else if (index == 2) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => ConverterScreen()),
              );
            } else if (index == 3) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder:
                      (_) => ProfileScreenWithCallback(
                        onPhotoUpdated: _onProfilePhotoUpdated,
                      ),
                ),
              );
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
            BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Nearby'),
            BottomNavigationBarItem(
              icon: Icon(Icons.swap_horiz),
              label: 'Converter',
            ),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          ],
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }
}

// Wrapper to pass callback to ProfileScreen
class ProfileScreenWithCallback extends StatelessWidget {
  final VoidCallback onPhotoUpdated;
  const ProfileScreenWithCallback({required this.onPhotoUpdated, super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileScreen(onPhotoUpdated: onPhotoUpdated);
  }
}
