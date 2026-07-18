import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/debt_model.dart';

class DebtProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DebtModel> _debts = [];
  StreamSubscription? _subscription;
  String? _currentUserId;

  List<DebtModel> get debts => [..._debts];
  
  double get totalDebt => _debts.fold(0.0, (acc, item) => acc + item.amount);
  double get totalPaid => _debts.fold(0.0, (acc, item) => acc + item.paidAmount);
  double get overallProgress => totalDebt > 0 ? (totalPaid / totalDebt) : 0;

  void setUser(String? userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;

    _subscription?.cancel();
    if (userId != null) {
      _subscription = _firestore
          .collection('users')
          .doc(userId)
          .collection('debts')
          .snapshots()
          .listen((snapshot) {
        _debts = snapshot.docs.map((doc) => DebtModel.fromMap(doc.data(), doc.id)).toList();
        notifyListeners();
      });
    } else {
      _debts = [];
      notifyListeners();
    }
  }

  Future<void> addDebt(DebtModel debt) async {
    if (_currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('debts')
        .add(debt.toMap());
  }

  Future<void> updateDebt(DebtModel debt) async {
    if (_currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('debts')
        .doc(debt.id)
        .update(debt.toMap());
  }

  Future<void> deleteDebt(String id) async {
    if (_currentUserId == null) return;
    await _firestore
        .collection('users')
        .doc(_currentUserId)
        .collection('debts')
        .doc(id)
        .delete();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
