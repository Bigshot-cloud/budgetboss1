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
      try {
        if (user != null) {
          print('Auth state changed: User is logged in (${user.uid})');
          _userModel = await _authService.getUserData(user.uid);
          if (_userModel == null) {
            print('User document not found in Firestore for UID: ${user.uid}');
          }
        } else {
          print('Auth state changed: No user logged in');
          _userModel = null;
        }
        notifyListeners();
      } catch (e) {
        print('Error in AuthProvider user stream: $e');
        _userModel = null;
        notifyListeners();
      }
    });
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      await _authService.signIn(email, password);
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
    _setLoading(true);
    try {
      await _authService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
        country: country,
      );
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
  }

  Future<void> updateUser(UserModel updatedUser) async {
    await _authService.updateUserData(updatedUser);
    _userModel = updatedUser;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
