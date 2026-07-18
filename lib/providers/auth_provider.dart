import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  UserModel? _userModel;
  bool _isLoading = false;
  StreamSubscription? _userDocSubscription;

  UserModel? get user => _userModel;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _authService.userStream.listen((User? user) async {
      debugPrint('Auth state changed: ${user != null ? "Logged In (${user.email})" : "Logged Out"}');
      
      _userDocSubscription?.cancel();
      
      if (user != null) {
        // Use a real-time listener for the user document to ensure state synchronization
        _userDocSubscription = _authService.getUserDataStream(user.uid).listen((userData) {
          if (userData != null) {
            _userModel = userData;
            debugPrint('User data synchronized for: ${_userModel?.email}');
            debugPrint('Profile Picture URL: ${_userModel?.profilePictureUrl}');
          } else {
            debugPrint('User document does not exist in Firestore for UID: ${user.uid}');
          }
          notifyListeners();
        }, onError: (e) {
          debugPrint('Error listening to user document: $e');
        });
      } else {
        _userModel = null;
        notifyListeners();
      }
    });
  }

  Future<void> login(String email, String password) async {
    debugPrint('Login attempt for: $email');
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
    debugPrint('Registration attempt for: $email');
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
    debugPrint('Logging out...');
    _userDocSubscription?.cancel();
    await _authService.signOut();
  }

  Future<void> updateUser(UserModel updatedUser) async {
    debugPrint('Updating user data in Firestore...');
    try {
      await _authService.updateUserData(updatedUser);
      // We don't necessarily need to update _userModel and notifyListeners manually
      // because the real-time listener in the constructor will handle it.
    } catch (e) {
      debugPrint('Failed to update user data: $e');
      rethrow;
    }
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
        debugPrint('Profile picture uploaded successfully. URL: $url');
      }
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
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
    } catch (e) {
      debugPrint('Error removing profile picture: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateUserPassword(String newPassword) async {
    debugPrint('Updating password...');
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

  @override
  void dispose() {
    _userDocSubscription?.cancel();
    super.dispose();
  }
}
