import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onPhotoUpdated;
  const ProfileScreen({super.key, this.onPhotoUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _changingPassword = false;
  final TextEditingController _oldPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  bool _loading = false;
  String? _error; // For displaying error messages
  String? _localProfilePhotoBase64;

  @override
  void initState() {
    super.initState();
    _loadLocalProfilePhoto();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  // Loads the locally stored profile photo from SharedPreferences
  Future<void> _loadLocalProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return; // Ensure widget is still mounted before setState
    setState(() {
      _localProfilePhotoBase64 = prefs.getString('profile_photo_base64');
    });
  }

  // Allows user to pick an image and saves it locally
  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    ); // Compress image
    if (picked == null) {
      debugPrint('No image selected.');
      return;
    }

    // Validate file type
    final fileName = picked.name.toLowerCase();
    if (!(fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a JPG or PNG image.')),
      );
      return;
    }

    setState(() => _loading = true); // Start loading indicator

    try {
      final bytes = await picked.readAsBytes();
      // Check file size (e.g., max 2MB for display, adjust as needed)
      if (bytes.length > 2 * 1024 * 1024) {
        // Reduced to 2MB for better performance
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Image too large. Please select an image smaller than 2MB.',
            ),
          ),
        );
        setState(() => _loading = false);
        return;
      }

      final base64Image = base64Encode(bytes);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_photo_base64', base64Image);

      await _loadLocalProfilePhoto(); // Update UI with new image
      if (widget.onPhotoUpdated != null) {
        widget.onPhotoUpdated!(); // Notify parent widgets (e.g., HomeScreen)
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile photo updated successfully!'),
          backgroundColor: Colors.green, // Success message color
        ),
      );
    } catch (e) {
      debugPrint('Error picking or saving image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile photo: ${e.toString()}'),
          backgroundColor:
              Theme.of(context).colorScheme.error, // Error message color
        ),
      );
    } finally {
      setState(() => _loading = false); // Stop loading indicator
    }
  }

  // Handles changing the user's password
  Future<void> _changePassword(BuildContext context) async {
    setState(() {
      _loading = true;
      _error = null; // Clear previous errors
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;

    if (user == null) {
      setState(() {
        _loading = false;
        _error = 'User not signed in.';
      });
      return;
    }

    final oldPassword = _oldPasswordController.text;
    final newPassword = _newPasswordController.text;

    if (oldPassword.isEmpty || newPassword.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Please fill in both old and new password fields.';
      });
      return;
    }
    if (newPassword.length < 6) {
      // Example: minimum password length
      setState(() {
        _loading = false;
        _error = 'New password must be at least 6 characters long.';
      });
      return;
    }
    if (oldPassword == newPassword) {
      setState(() {
        _loading = false;
        _error = 'New password cannot be the same as the old password.';
      });
      return;
    }

    try {
      // In a real scenario, you'd reauthenticate with Firebase and then update.
      // For this mock, we compare with stored encrypted password.
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.email)
              .get();

      // Ensure doc exists and contains password
      if (!doc.exists ||
          doc.data() == null ||
          !doc.data()!.containsKey('password')) {
        setState(() {
          _loading = false;
          _error = 'User data not found or password not set.';
        });
        return;
      }

      final storedEncryptedOldPassword = doc['password'];
      final enteredEncryptedOldPassword = authService.encryptPassword(
        oldPassword,
      );

      if (storedEncryptedOldPassword != enteredEncryptedOldPassword) {
        setState(() {
          _loading = false;
          _error = 'Old password is incorrect.';
        });
        return;
      }

      // Encrypt the new password and update in Firestore
      final encryptedNewPassword = authService.encryptPassword(newPassword);
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .update({'password': encryptedNewPassword});

      // Clear text fields and reset state on success
      _oldPasswordController.clear();
      _newPasswordController.clear();
      setState(() {
        _loading = false;
        _changingPassword = false; // Collapse password change section
        _error = null; // Clear any errors
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully!'),
          backgroundColor: Colors.green, // Success message color
        ),
      );
    } catch (e) {
      debugPrint('Error changing password: $e');
      setState(() {
        _loading = false;
        _error = 'Failed to change password: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password change failed: ${e.toString()}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  // Private method to build the unauthenticated state UI
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
              'Please sign in to manage your profile settings.',
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

    return Scaffold(
      appBar: AppBar(title: const Text('Profile Settings')),
      body:
          user == null
              ? _buildUnauthenticatedState(context)
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch, // Stretch children
                  children: [
                    // --- Profile Photo Section ---
                    Center(
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 120, // Larger avatar size
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child:
                                  _localProfilePhotoBase64 != null
                                      ? Image.memory(
                                        base64Decode(_localProfilePhotoBase64!),
                                        fit:
                                            BoxFit
                                                .cover, // Ensure image covers the circle
                                        errorBuilder: (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          // Fallback on error (e.g., corrupted base64)
                                          return Icon(
                                            Icons.person_rounded,
                                            size: 60,
                                            color:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                          );
                                        },
                                      )
                                      : Icon(
                                        Icons
                                            .person_rounded, // Default person icon
                                        size: 60,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                      ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context)
                                        .colorScheme
                                        .primary, // Brand blue background
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.camera_alt_rounded, // Camera icon
                                  color: Colors.white, // White icon
                                ),
                                onPressed:
                                    _loading
                                        ? null
                                        : () => _pickAndUploadPhoto(context),
                                tooltip: 'Change Profile Photo',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // --- User Info Card ---
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              user.name != null && user.name!.isNotEmpty
                                  ? user.name!
                                  : 'Nomad Explorer', // Default name
                              style: Theme.of(
                                context,
                              ).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              user.email.isNotEmpty
                                  ? user.email
                                  : 'No Email Provided',
                              style: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Change Password Section ---
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Password Settings',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            AnimatedCrossFade(
                              duration: const Duration(milliseconds: 300),
                              crossFadeState:
                                  _changingPassword
                                      ? CrossFadeState.showSecond
                                      : CrossFadeState.showFirst,
                              firstChild: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _changingPassword = true;
                                    _error = null; // Clear error when opening
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12.0),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16.0,
                                  ),
                                  minimumSize: const Size.fromHeight(50),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'Change Password',
                                  style: TextStyle(
                                    fontSize: 18.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              secondChild: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  TextField(
                                    controller: _oldPasswordController,
                                    decoration: inputDecoration.copyWith(
                                      labelText: 'Old Password',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                      ),
                                    ),
                                    obscureText: true,
                                  ),
                                  const SizedBox(height: 16),
                                  TextField(
                                    controller: _newPasswordController,
                                    decoration: inputDecoration.copyWith(
                                      labelText: 'New Password',
                                      prefixIcon: const Icon(
                                        Icons.lock_reset_rounded,
                                      ),
                                    ),
                                    obscureText: true,
                                  ),
                                  const SizedBox(height: 16),
                                  if (_error != null)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 16,
                                      ),
                                      child: Text(
                                        _error!,
                                        style: TextStyle(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.error,
                                          fontSize: 15.0,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed:
                                              _loading
                                                  ? null
                                                  : () =>
                                                      _changePassword(context),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                            foregroundColor:
                                                Theme.of(
                                                  context,
                                                ).colorScheme.onPrimary,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16.0,
                                            ),
                                            elevation: 0,
                                          ),
                                          child:
                                              _loading
                                                  ? SizedBox(
                                                    width: 20,
                                                    height: 20,
                                                    child:
                                                        CircularProgressIndicator(
                                                          strokeWidth: 2.5,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .onPrimary,
                                                        ),
                                                  )
                                                  : const Text(
                                                    'Update Password',
                                                    style: TextStyle(
                                                      fontSize: 16.0,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: TextButton(
                                          onPressed:
                                              _loading
                                                  ? null
                                                  : () {
                                                    setState(() {
                                                      _changingPassword = false;
                                                      _error =
                                                          null; // Clear error on cancel
                                                      _oldPasswordController
                                                          .clear();
                                                      _newPasswordController
                                                          .clear();
                                                    });
                                                  },
                                          style: TextButton.styleFrom(
                                            foregroundColor: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withOpacity(0.7),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16.0,
                                            ),
                                          ),
                                          child: const Text(
                                            'Cancel',
                                            style: TextStyle(fontSize: 16.0),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Logout Button ---
                    ElevatedButton.icon(
                      onPressed:
                          _loading
                              ? null
                              : () async {
                                await Provider.of<AuthService>(
                                  context,
                                  listen: false,
                                ).signOut();
                                if (context.mounted) {
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                    (route) =>
                                        false, // Remove all routes from stack
                                  );
                                }
                              },
                      icon: const Icon(Icons.logout_rounded),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(
                              context,
                            ).colorScheme.error, // Use a red color for logout
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        minimumSize: const Size.fromHeight(50),
                        elevation: 0,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
