import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _userModel;
  bool _isLoading = false;

  UserModel? get user => _userModel;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _authService.userStream.listen((User? user) async {
      debugPrint('Auth state changed: ${user != null ? "Logged In (${user.email})" : "Logged Out"}');
      try {
        if (user != null) {
          _userModel = await _authService.getUserData(user.uid);
          if (_userModel == null) {
            debugPrint('User document not found in Firestore for UID: ${user.uid}');
          }
        } else {
          _userModel = null;
        }
        notifyListeners();
      } catch (e) {
        debugPrint('Error in AuthProvider user stream: $e');
        _userModel = null;
        notifyListeners();
      }
    });
  }

  Future<void> login(String email, String password) async {
    debugPrint('Login button pressed for: $email');
    _setLoading(true);
    try {
      await _authService.signIn(email, password);
      debugPrint('Authentication successful');
    } catch (e) {
      debugPrint('Authentication failed: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? country,
  }) async {
    debugPrint('Registration started for: $email');
    _setLoading(true);
    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        country: country,
      );
      debugPrint('Registration successful');
    } catch (e) {
      debugPrint('Registration failed: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    debugPrint('Logging out user...');
    await _authService.signOut();
  }

  Future<void> updateUser(UserModel updatedUser) async {
    debugPrint('Updating user data in Firestore...');
    await _authService.updateUserData(updatedUser);
    _userModel = updatedUser;
    notifyListeners();
  }

  Future<void> uploadProfilePicture(File imageFile) async {
    if (_userModel == null) return;
    debugPrint('Uploading profile picture...');
    _setLoading(true);
    try {
      final url = await _authService.uploadProfilePicture(_userModel!.id, imageFile);
      if (url != null) {
        final updatedUser = _userModel!.copyWith(profilePictureUrl: () => url);
        await updateUser(updatedUser);
        debugPrint('Profile picture uploaded and URL saved: $url');
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeProfilePicture() async {
    if (_userModel == null) return;
    debugPrint('Removing profile picture...');
    _setLoading(true);
    try {
      await _authService.removeProfilePicture(_userModel!.id);
      final updatedUser = _userModel!.copyWith(profilePictureUrl: () => null);
      await updateUser(updatedUser);
      debugPrint('Profile picture removed successfully');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserPassword(String newPassword) async {
    debugPrint('Changing user password...');
    await _authService.changePassword(newPassword);
  }

  Future<void> resetPassword(String email) async {
    debugPrint('Sending password reset email to: $email');
    await _authService.resetPassword(email);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
