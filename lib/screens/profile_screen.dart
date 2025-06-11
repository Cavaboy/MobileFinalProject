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
  String? _error;
  String? _localProfilePhotoBase64;

  @override
  void initState() {
    super.initState();
    _loadLocalProfilePhoto();
  }

  Future<void> _loadLocalProfilePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _localProfilePhotoBase64 = prefs.getString('profile_photo_base64');
    });
  }

  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) {
      debugPrint('No image selected.');
      return;
    }
    // Validate file type
    final fileName = picked.name.toLowerCase();
    debugPrint('Selected file: $fileName');
    if (!(fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg') ||
        fileName.endsWith('.png'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a JPG or PNG image.')),
      );
      return;
    }
    // Check file size (e.g., max 5MB)
    final bytes = await picked.readAsBytes();
    debugPrint('Image size: ${bytes.length} bytes');
    if (bytes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected image is empty or corrupted.')),
      );
      return;
    }
    if (bytes.length > 5 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Image too large. Please select an image smaller than 5MB.',
          ),
        ),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final base64Image = base64Encode(bytes);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_photo_base64', base64Image);
      await _loadLocalProfilePhoto(); // Ensure UI updates with new image
      if (widget.onPhotoUpdated != null) widget.onPhotoUpdated!();
      setState(() {
        _loading = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile photo updated!')));
    } catch (e) {
      setState(() => _loading = false);
      debugPrint('Unknown error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An unknown error occurred while saving.'),
        ),
      );
    }
  }

  Future<void> _changePassword(BuildContext context) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.user;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .get();
    final encryptedOldPassword = authService.encryptPassword(
      _oldPasswordController.text,
    );
    if (doc['password'] != encryptedOldPassword) {
      setState(() {
        _loading = false;
        _error = 'Old password is incorrect.';
      });
      return;
    }
    final encryptedNewPassword = authService.encryptPassword(
      _newPasswordController.text,
    );
    await FirebaseFirestore.instance.collection('users').doc(user.email).update(
      {'password': encryptedNewPassword},
    );
    setState(() {
      _loading = false;
      _changingPassword = false;
    });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Password changed!')));
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context).user;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Center(
        child:
            user == null
                ? const Text(
                  'Not signed in',
                  style: TextStyle(color: Colors.red),
                )
                : SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          _localProfilePhotoBase64 != null
                              ? CircleAvatar(
                                radius: 40,
                                backgroundImage: MemoryImage(
                                  base64Decode(_localProfilePhotoBase64!),
                                ),
                              )
                              : const CircleAvatar(
                                radius: 40,
                                child: Icon(Icons.person, size: 40),
                              ),
                          IconButton(
                            icon: const Icon(Icons.camera_alt),
                            onPressed:
                                _loading
                                    ? null
                                    : () => _pickAndUploadPhoto(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.name ?? 'No Name',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(user.email),
                      const SizedBox(height: 16),
                      if (_changingPassword)
                        Column(
                          children: [
                            TextField(
                              controller: _oldPasswordController,
                              decoration: const InputDecoration(
                                labelText: 'Old Password',
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _newPasswordController,
                              decoration: const InputDecoration(
                                labelText: 'New Password',
                              ),
                              obscureText: true,
                            ),
                            const SizedBox(height: 8),
                            if (_error != null)
                              Text(
                                _error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ElevatedButton(
                                  onPressed:
                                      _loading
                                          ? null
                                          : () => _changePassword(context),
                                  child: const Text('Change Password'),
                                ),
                                const SizedBox(width: 8),
                                TextButton(
                                  onPressed:
                                      _loading
                                          ? null
                                          : () {
                                            setState(() {
                                              _changingPassword = false;
                                            });
                                          },
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
                          ],
                        )
                      else
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _changingPassword = true;
                            });
                          },
                          child: const Text('Change Password'),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
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
                                      (route) => false,
                                    );
                                  }
                                },
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
