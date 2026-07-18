import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import '../../models/user_model.dart';
// import 'email_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  // Temporarily disabled SMTP Email Service
  // final EmailService _emailService = EmailService();

  Stream<User?> get userStream => _auth.authStateChanges();

  Future<String?> uploadProfilePicture(String userId, File imageFile) async {
    try {
      final ref = _storage.ref().child('profile_pictures').child('$userId.jpg');
      
      // Add metadata to help with caching and browser rendering
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': userId},
      );

      await ref.putFile(imageFile, metadata);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint('Error uploading profile picture: $e');
      return null;
    }
  }

  Future<void> removeProfilePicture(String userId) async {
    try {
      await _storage.ref().child('profile_pictures').child('$userId.jpg').delete();
    } catch (e) {
      debugPrint('Error deleting profile picture: $e');
    }
  }

  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    String? country,
  }) async {
    try {
      debugPrint('Attempting to sign up with: $email');
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        debugPrint('User created successfully: ${credential.user!.uid}');
        
        // Auto-assign currency based on country
        String currency = 'GH₵';
        if (country != null) {
          if (country == 'United States') {
            currency = 'USD (\$)';
          } else if (country == 'United Kingdom') {
            currency = 'GBP (£)';
          } else if (country == 'Europe') {
            currency = 'EUR (€)';
          }
        }

        UserModel user = UserModel(
          id: credential.user!.uid,
          fullName: fullName,
          email: email,
          phoneNumber: phoneNumber,
          country: country,
          preferences: {
            'currency': currency,
            'theme': 'dark',
            'language': 'en',
          },
        );
        await _firestore.collection('users').doc(user.id).set(user.toMap());
        
        // Phase 7: Welcome notification
        await _firestore.collection('users').doc(user.id).collection('notifications').add({
          'title': 'Welcome to BudgetBoss! 👑',
          'body': 'Start managing your finances like a pro.',
          'date': Timestamp.now(),
          'isRead': false,
        });

        // Temporarily disabled SMTP Welcome Email
        // await _emailService.sendWelcomeEmail(email, fullName);

        // Phase 10: Ensure user is signed out after registration so they have to log in
        await _auth.signOut();

        debugPrint('User document and welcome notification created, and signed out');
      }
      return credential;
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during signUp: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Generic error during signUp: $e');
      rethrow;
    }
  }

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      debugPrint('Attempting to sign in with: $email');
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException catch (e) {
      debugPrint('FirebaseAuthException during signIn: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Generic error during signIn: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getUserData(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Stream<UserModel?> getUserDataStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    });
  }

  Future<void> updateUserData(UserModel user) async {
    await _firestore.collection('users').doc(user.id).update(user.toMap());
  }

  Future<void> changePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }
}
