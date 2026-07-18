import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/savings_model.dart';

class SavingsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<SavingsModel> _goals = [];
  StreamSubscription? _subscription;
  String? _currentUserId;

  List<SavingsModel> get goals => [..._goals];
  
  double get totalSaved => _goals.fold(0.0, (acc, item) => acc + item.savedAmount);
  double get totalTarget => _goals.fold(0.0, (acc, item) => acc + item.targetAmount);

  void setUser(String? userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;

    _subscription?.cancel();
    if (userId != null) {
      _subscription = _firestore
          .collection('users')
          .doc(userId)
          .collection('savings')
          .snapshots()
          .listen((snapshot) {
        _goals = snapshot.docs.map((doc) => SavingsModel.fromMap(doc.data(), doc.id)).toList();
        notifyListeners();
      });
    } else {
      _goals = [];
      notifyListeners();
    }
  }

  Future<void> addGoal(SavingsModel goal) async {
    if (_currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('savings')
        .add(goal.toMap());
  }

  Future<void> updateGoal(SavingsModel goal) async {
    if (_currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('savings')
        .doc(goal.id)
        .update(goal.toMap());
  }

  Future<void> deleteGoal(String id) async {
    if (_currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('savings')
        .doc(id)
        .delete();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
