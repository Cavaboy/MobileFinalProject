import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  UserModel? _user;
  UserModel? get user => _user;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AuthService() {
    _loadUserFromPrefs();
  }

  Future<void> _loadUserFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('logged_in_email');
    if (email != null) {
      final userDoc = await _firestore.collection('users').doc(email).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        _user = UserModel(
          uid: data['uid'],
          email: data['email'],
          name: data['name'],
          photoUrl: data['photoUrl'],
        );
        notifyListeners();
      }
    }
  }

  // Caesar cipher encryption
  String _encrypt(String input, int key) {
    return String.fromCharCodes(input.codeUnits.map((c) => c + key));
  }

  // Firestore sign up with Caesar cipher
  Future<UserModel?> signUp(
    String email,
    String password,
    String username,
  ) async {
    final userDoc = await _firestore.collection('users').doc(email).get();
    if (userDoc.exists) {
      return null; // User already exists
    }
    final encryptedPassword = _encrypt(password, 3);
    final userData = {
      'email': email,
      'password': encryptedPassword,
      'name': username,
      'photoUrl': null,
      'uid': email, // Use email as uid for simplicity
    };
    await _firestore.collection('users').doc(email).set(userData);
    _user = UserModel(uid: email, email: email, name: username, photoUrl: null);
    notifyListeners();
    return _user;
  }

  // Firestore sign in with Caesar cipher
  Future<UserModel?> signIn(String email, String password) async {
    final userDoc = await _firestore.collection('users').doc(email).get();
    if (userDoc.exists) {
      final data = userDoc.data()!;
      final encryptedPassword = _encrypt(password, 3);
      if (data['password'] == encryptedPassword) {
        _user = UserModel(
          uid: data['uid'],
          email: data['email'],
          name: data['name'],
          photoUrl: data['photoUrl'],
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('logged_in_email', email);
        notifyListeners();
        return _user;
      }
    }
    return null;
  }

  // Mock sign out
  Future<void> signOut() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('logged_in_email');
    notifyListeners();
  }

  // Placeholder for Firestore REST API usage for DB features
  // TODO: Implement Firestore REST API calls here if needed

  String encryptPassword(String password) {
    return _encrypt(password, 3);
  }
}
