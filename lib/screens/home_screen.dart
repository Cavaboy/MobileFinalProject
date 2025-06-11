import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/pedometer_service.dart';
import 'login_screen.dart'; // Import LoginScreen

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

  // Reloads the profile photo from SharedPreferences
  Future<void> _loadLocalProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return; // Check if the widget is still in the tree
    setState(() {
      _localProfilePhotoBase64 = prefs.getString('profile_photo_base64');
    });
  }

  // Callback for when the profile photo is updated (e.g., from ProfileScreen)
  void _onProfilePhotoUpdated() {
    _loadLocalProfilePhoto(); // Reload the photo when updated
  }

  @override
  Widget build(BuildContext context) {
    // Provide PedometerService to the widget tree
    return ChangeNotifierProvider(
      create: (_) {
        final pedometerService = PedometerService();
        pedometerService.start(); // Start listening for step updates
        return pedometerService;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('NomadDaily'),
          // The AppBar style is inherited from the ThemeData in main.dart
        ),
        body: Center(
          child: SingleChildScrollView( // Allows content to scroll on smaller screens
            padding: const EdgeInsets.all(24.0), // Overall padding for the screen content
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch children for better layout
              children: [
                // --- Welcome Section ---
                Text(
                  'Welcome to NomadDaily!',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Your daily companion for remote work and travel.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40), // More space before the main content

                // --- Pedometer Card Section ---
                Consumer<PedometerService>(
                  builder: (context, pedometer, _) {
                    return Card(
                      elevation: 2, // Subtle shadow for the card
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0), // Rounded corners for the card
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 0), // No horizontal margin, allow stretch
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.directions_walk_rounded, // Walking icon
                              size: 48,
                              color: Theme.of(context).colorScheme.primary, // Brand blue icon
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Steps Today',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              pedometer.steps.toString(),
                              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                                    fontSize: 64, // Large font size for step count
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.primary, // Brand blue for the count
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40), // Space after pedometer card

                // --- User Info / Authentication Prompt Section ---
                Builder(
                  builder: (context) {
                    final user = Provider.of<AuthService>(context).user;
                    if (user == null) {
                      // If user is not signed in, show sign-in/register buttons
                      return Column(
                        children: [
                          Text(
                            'Sign in to personalize your experience.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              // Navigate to LoginScreen
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Theme.of(context).colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16.0),
                              minimumSize: const Size.fromHeight(50),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Sign In',
                              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              // Navigate to LoginScreen (which handles register toggle)
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const LoginScreen()), // LoginScreen handles registration toggle
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.primary,
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                            ),
                            child: const Text(
                              "Don't have an account? Create one",
                              style: TextStyle(fontSize: 16.0),
                            ),
                          ),
                        ],
                      );
                    }
                    // If user is signed in, display profile information
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      margin: const EdgeInsets.symmetric(horizontal: 0),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: [
                            // Profile Photo
                            if (_localProfilePhotoBase64 != null)
                              CircleAvatar(
                                radius: 40, // Slightly larger avatar
                                backgroundImage: MemoryImage(
                                  base64Decode(_localProfilePhotoBase64!),
                                ),
                                onBackgroundImageError: (exception, stackTrace) {
                                  // Fallback to network image or default icon on error
                                  print('Error loading local profile photo: $exception');
                                  // Consider clearing _localProfilePhotoBase64 here or loading default
                                },
                              )
                            else if (user.photoUrl != null && user.photoUrl!.isNotEmpty)
                              CircleAvatar(
                                radius: 40,
                                backgroundImage: NetworkImage(user.photoUrl!),
                                onBackgroundImageError: (exception, stackTrace) {
                                  // Fallback to default icon on network image error
                                  print('Error loading network profile photo: $exception');
                                },
                              )
                            else
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1), // Subtle background
                                child: Icon(Icons.person_rounded, size: 48, color: Theme.of(context).colorScheme.primary),
                              ),
                            const SizedBox(height: 12),
                            // User Name
                            Text(
                              user.name != null && user.name!.isNotEmpty
                                  ? user.name!
                                  : 'Nomad Explorer', // Default name
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            // User Email
                            Text(
                              user.email.isNotEmpty ? user.email : 'No Email Provided',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                            ),
                            const SizedBox(height: 16),
                            // Optional: Button to go to profile settings
                            OutlinedButton.icon(
                              onPressed: () {
                                // This should navigate to the profile screen via MainNavigation
                                // For now, we'll assume the bottom navigation handles this.
                                // If you want a direct link, you'd trigger MainNavigation's state change.
                                // For simplicity, let's just push to profile screen directly for demo.
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProfileScreenWithCallback(
                                      onPhotoUpdated: _onProfilePhotoUpdated,
                                    ),
                                  ),
                                );
                              },
                              icon: Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.primary),
                              label: Text(
                                'Edit Profile',
                                style: TextStyle(color: Theme.of(context).colorScheme.primary),
                              ),
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        // The BottomNavigationBar is managed by MainNavigation in main.dart,
        // so it should not be included here.
      ),
    );
  }
}

// Wrapper to pass callback to ProfileScreen (kept for compatibility)
class ProfileScreenWithCallback extends StatelessWidget {
  final VoidCallback onPhotoUpdated;
  const ProfileScreenWithCallback({required this.onPhotoUpdated, super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming ProfileScreen now takes a callback
    return ProfileScreen(onPhotoUpdated: onPhotoUpdated);
  }
}

// Dummy ProfileScreen to satisfy import for ProfileScreenWithCallback
// You should have your actual ProfileScreen implementation in 'profile_screen.dart'
// This is just a placeholder to make the code runnable in isolation.
class ProfileScreen extends StatelessWidget {
  final VoidCallback onPhotoUpdated;
  const ProfileScreen({required this.onPhotoUpdated, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Settings')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Profile Screen Content'),
            // Example button to simulate photo update
            ElevatedButton(
              onPressed: () {
                // Simulate updating photo
                // In a real app, this would involve picking an image and saving it
                // Then call onPhotoUpdated();
                onPhotoUpdated();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Simulated photo update!')),
                );
              },
              child: const Text('Simulate Photo Update'),
            ),
          ],
        ),
      ),
    );
  }
}