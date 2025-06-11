import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/pedometer_service.dart';
import 'login_screen.dart'; // Import LoginScreen for unauthenticated state navigation

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildUnauthenticatedState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_rounded, // Lock icon for signed-out state
              size: 80,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'Access Restricted',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Please sign in to personalize your experience and access all features.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 30.0,
                ),
                elevation: 0,
              ),
              child: const Text(
                'Sign In Now',
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the current user from AuthService
    final user = Provider.of<AuthService>(context).user;

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
        body:
            user == null
                ? _buildUnauthenticatedState(context)
                : SingleChildScrollView(
                  // Allows content to scroll on smaller screens
                  padding: const EdgeInsets.all(
                    24.0,
                  ), // Overall padding for the screen content
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .stretch, // Stretch children for better layout
                    children: [
                      // --- Welcome Message Section (Profile photo removed) ---
                      Consumer<AuthService>(
                        // Use consumer here for user info
                        builder: (context, authService, _) {
                          final user = authService.user;
                          final username =
                              (user?.name != null &&
                                      user?.name!.isNotEmpty == true)
                                  ? user!.name!
                                  : 'Explorer';
                          return Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start, // Align content to the left
                            children: [
                              // Profile photo is removed as per request.
                              // Welcome Message
                              Text(
                                'Hi, $username welcome to NomadDaily!',
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onBackground,
                                ),
                                textAlign:
                                    TextAlign.start, // Align text to start
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your daily companion for remote work and travel.',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onBackground.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.start,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(
                        height: 40,
                      ), // More space before the main content
                      // --- Pedometer Card Section ---
                      Consumer<PedometerService>(
                        builder: (context, pedometer, _) {
                          return Card(
                            elevation: 2, // Subtle shadow for the card
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                16.0,
                              ), // Rounded corners for the card
                            ),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 0,
                            ), // No horizontal margin, allow stretch
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 24.0,
                                horizontal: 20.0,
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons
                                        .directions_walk_rounded, // Walking icon
                                    size: 48,
                                    color:
                                        Theme.of(context)
                                            .colorScheme
                                            .primary, // Brand blue icon
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Steps Today',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    pedometer.steps.toString(),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.displayLarge?.copyWith(
                                      fontSize:
                                          64, // Large font size for step count
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Theme.of(context)
                                              .colorScheme
                                              .primary, // Brand blue for the count
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 40), // Space after pedometer card
                      Text(
                        'Impressions and Message:', // Updated heading
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                        textAlign: TextAlign.start,
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 1, // Subtle shadow for the card
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            12.0,
                          ), // Rounded corners
                        ),
                        margin: const EdgeInsets.only(
                          bottom: 16,
                        ), // Space between cards
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Impression',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context)
                                          .colorScheme
                                          .primary, // Brand blue for heading
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'kesan would be here',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Message',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Pesan would be here',
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
