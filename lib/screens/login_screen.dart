import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
// Note: HomeScreen, MapScreen, ConverterScreen, ProfileScreen are not directly
// used in the LoginScreen's build method after successful authentication.
// The MainNavigation widget (defined in main.dart) handles routing after login.
// You can remove these imports if they are not used elsewhere in this file.

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  bool _loading = false;
  String? _error; // To display error messages
  bool _isRegistering = false; // To toggle between login and register UI

  // Clean up unused state variables from previous version
  // int _selectedIndex = 0; // Handled by MainNavigation
  // bool _isLoading = false; // Consolidated with _loading
  // String? _errorMessage; // Consolidated with _error
  // final List<Widget> _screens = const []; // Handled by MainNavigation

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  // Authentication logic consolidated and improved for UI feedback
  Future<void> _authenticate(BuildContext context) async {
    setState(() {
      _loading = true;
      _error = null; // Clear previous errors
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final username = _usernameController.text.trim();

    try {
      if (_isRegistering) {
        // Attempt to sign up
        final user = await authService.signUp(email, password, username);
        if (user != null) {
          // Show success message if registration is successful
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful!'),
              backgroundColor: Colors.green, // Green for success
            ),
          );
          // Clear loading and error after successful registration
          setState(() {
            _loading = false;
            _error = null;
            _isRegistering = false; // Switch to login after registration
          });
          return;
        } else {
          // Handle cases where sign-up might return null (e.g., user already exists)
          setState(() {
            _error =
                'Registration failed. User might already exist or invalid data.';
          });
        }
      } else {
        // Attempt to sign in
        final user = await authService.signIn(email, password);
        if (user == null) {
          // Show error message if sign-in fails
          setState(() {
            _error =
                'Invalid credentials. Please check your email and password.';
            _loading = false;
          });
          return;
        }
      }
    } catch (e) {
      // Catch and display any exceptions during authentication
      setState(() {
        _error = 'Error: ${e.toString()}'; // More specific error message
      });
      // Optionally show a SnackBar for critical errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Authentication failed: ${e.toString()}'),
          backgroundColor:
              Theme.of(context).colorScheme.error, // Red for errors
        ),
      );
    } finally {
      // Only reset loading if still mounted and not already reset
      if (mounted && _loading) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // The AppLauncher in main.dart already handles redirecting to MainNavigation
    // once a user is authenticated. So, this check and conditional return
    // is not strictly necessary here, but keeping it for now if there's a specific
    // reason for it in your architecture.
    final user = Provider.of<AuthService>(context).user;
    if (user != null) {
      // If user is authenticated, this screen should ideally not be visible.
      // It implies a redirect has happened or is about to happen from AppLauncher.
      // Returning an empty container or a simple loading spinner here is fine
      // as the user will be quickly redirected by the parent AppLauncher.
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Define border styles for text fields based on theme
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0), // Rounded corners
      borderSide: BorderSide.none, // No visible border initially
    );

    final OutlineInputBorder focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: BorderSide(
        color: Theme.of(context).colorScheme.primary, // Brand blue when focused
        width: 2.0, // Slightly thicker border when focused
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isRegistering ? 'Create Account' : 'Sign In',
        ), // More user-friendly titles
      ),
      body: Center(
        child: SingleChildScrollView(
          // Allow scrolling on smaller screens if content overflows
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.stretch, // Stretch children to fill width
            children: [
              // AnimatedSwitcher for username field
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child:
                    _isRegistering
                        ? Column(
                          key: const ValueKey(
                            'registerFields',
                          ), // Unique key for AnimatedSwitcher
                          children: [
                            TextField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                hintText: 'Username',
                                prefixIcon: const Icon(
                                  Icons.person_outline_rounded,
                                ),
                                filled: true,
                                fillColor: const Color(
                                  0xFFF0F0F0,
                                ), // Light grey fill
                                border: border,
                                enabledBorder: border,
                                focusedBorder: focusedBorder,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                  horizontal: 20.0,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        )
                        : const SizedBox.shrink(
                          key: ValueKey('loginFields'),
                        ), // Hide username field for login
              ),

              TextField(
                controller: _emailController,
                keyboardType:
                    TextInputType.emailAddress, // Optimized for email input
                decoration: InputDecoration(
                  hintText: 'Email',
                  prefixIcon: const Icon(Icons.email_outlined),
                  filled: true,
                  fillColor: const Color(0xFFF0F0F0),
                  border: border,
                  enabledBorder: border,
                  focusedBorder: focusedBorder,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 20.0,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true, // Hide password
                decoration: InputDecoration(
                  hintText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF0F0F0),
                  border: border,
                  enabledBorder: border,
                  focusedBorder: focusedBorder,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 20.0,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Display error message if present
              if (_error != null) ...[
                Text(
                  _error!,
                  style: TextStyle(
                    color:
                        Theme.of(
                          context,
                        ).colorScheme.error, // Use theme error color
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              // Main authentication button
              _loading
                  ? Center(
                    child: CircularProgressIndicator(
                      color:
                          Theme.of(
                            context,
                          ).colorScheme.primary, // Use theme primary color
                    ),
                  )
                  : ElevatedButton(
                    onPressed: () => _authenticate(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(
                            context,
                          ).colorScheme.primary, // Brand blue background
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
                      ), // Ensure a minimum height for the button
                      elevation: 0, // No shadow for minimalist look
                    ),
                    child: Text(
                      _isRegistering
                          ? 'Create Account'
                          : 'Sign In', // Action-oriented text
                      style: const TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              const SizedBox(height: 20),

              // Toggle between login and register
              TextButton(
                onPressed: () {
                  setState(() {
                    _isRegistering = !_isRegistering;
                    _error = null; // Clear error when switching modes
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor:
                      Theme.of(context).colorScheme.primary, // Brand blue text
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                ),
                child: Text(
                  _isRegistering
                      ? 'Already have an account? Sign In'
                      : 'Don\'t have an account? Create one',
                  style: const TextStyle(fontSize: 16.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
