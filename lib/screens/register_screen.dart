import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import 'login_screen.dart' show LoginScreen;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _loading = false;
  String? _error; // For displaying authentication errors

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Handles the user registration process
  Future<void> _register() async {
    setState(() {
      _loading = true;
      _error = null; // Clear previous errors
    });

    // Basic input validation
    if (_nameController.text.trim().isEmpty) {
      setState(() {
        _error = 'Please enter your name.';
        _loading = false;
      });
      return;
    }
    if (_emailController.text.trim().isEmpty ||
        !_emailController.text.contains('@')) {
      setState(() {
        _error = 'Please enter a valid email address.';
        _loading = false;
      });
      return;
    }
    if (_passwordController.text.isEmpty ||
        _passwordController.text.length < 6) {
      setState(() {
        _error = 'Password must be at least 6 characters long.';
        _loading = false;
      });
      return;
    }
    if (_confirmPasswordController.text != _passwordController.text) {
      setState(() {
        _error = 'Passwords do not match.';
        _loading = false;
      });
      return;
    }

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = await authService.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );

      if (user == null) {
        // If signUp returns null, it usually means user already exists or another issue occurred
        throw Exception(
          'Registration failed. This email might already be in use.',
        );
      }

      // Show success message and navigate to LoginScreen
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please sign in.'),
            backgroundColor: Colors.green, // Green for success
          ),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } catch (e) {
      // Catch and display any exceptions during registration
      setState(() {
        _error =
            'Registration failed: ${e.toString()}'; // More specific error message
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor:
                Theme.of(context).colorScheme.error, // Red for errors
          ),
        );
      }
    } finally {
      // Ensure loading state is reset
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;

    // Define InputDecoration styles for consistent text fields
    final InputDecoration inputDecoration = InputDecoration(
      filled: true,
      fillColor: const Color(0xFFF0F0F0), // Light grey background
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none, // No visible border initially
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.0),
        borderSide: BorderSide(
          color:
              Theme.of(context).colorScheme.primary, // Brand blue when focused
          width: 2.0,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 16.0,
        horizontal: 20.0,
      ),
    );

    // If user is already signed in, simply show a message and maybe redirect.
    // The AppLauncher in main.dart should ideally prevent reaching this screen
    // if a user is already authenticated.
    if (user != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Register')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline_rounded,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                Text(
                  'You are already signed in as ${user.email}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Navigate back to the home screen or main navigation
                    Navigator.of(
                      context,
                    ).pop(); // Or pushReplacement to MainNavigation
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
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Account'),
      ), // More inviting title
      body: Center(
        child: SingleChildScrollView(
          // Added to prevent overflow on smaller screens
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Stretch children to fill width
            children: [
              Text(
                'Join NomadDaily to explore features!',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onBackground,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              TextField(
                controller: _nameController,
                decoration: inputDecoration.copyWith(
                  hintText: 'Full Name',
                  labelText: 'Name',
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: inputDecoration.copyWith(
                  hintText: 'Email Address',
                  labelText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: inputDecoration.copyWith(
                  hintText: 'Password (min. 6 characters)',
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: inputDecoration.copyWith(
                  hintText: 'Re-enter your password',
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                ),
              ),
              const SizedBox(height: 24),

              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _error!,
                    style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.error, // Red from theme
                      fontSize: 15.0,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              ElevatedButton(
                onPressed: _loading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Theme.of(context).colorScheme.primary, // Brand blue
                  foregroundColor:
                      Theme.of(context).colorScheme.onPrimary, // White text
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12.0,
                    ), // Rounded corners
                  ),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                  ), // Comfortable padding
                  minimumSize: const Size.fromHeight(
                    50,
                  ), // Ensure a minimum height
                  elevation: 0, // No shadow for minimalist look
                ),
                child:
                    _loading
                        ? SizedBox(
                          width: 20, // Slightly larger spinner
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5, // Thicker spinner
                            color:
                                Theme.of(context)
                                    .colorScheme
                                    .onPrimary, // White spinner on blue button
                          ),
                        )
                        : const Text(
                          'Create Account', // Clear call to action
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
              const SizedBox(height: 20),

              TextButton(
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).colorScheme.primary, // Brand blue text
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                child: const Text(
                  'Already have an account? Sign In', // Clear navigation
                  style: TextStyle(fontSize: 16.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
