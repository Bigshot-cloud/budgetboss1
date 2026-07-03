import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/transaction_service.dart';
import '../models/transaction.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _service = TransactionService();
  List<TransactionModel> _transactions = [];
  StreamSubscription? _subscription;

  List<TransactionModel> get transactions => [..._transactions];

  List<TransactionModel> get recentTransactions {
    return _transactions.take(5).toList();
  }

  void setUser(String? userId) {
    _subscription?.cancel();
    if (userId != null) {
      _subscription = _service.getTransactionsStream(userId).listen((data) {
        _transactions = data;
        notifyListeners();
      });
    } else {
      _transactions = [];
      notifyListeners();
    }
  }

  double get totalBalance {
    double income = _transactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0, (sum, tx) => sum + tx.amount);
    double expense = _transactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0, (sum, tx) => sum + tx.amount);
    return income - expense;
  }

  double get totalIncome => _transactions
      .where((tx) => tx.type == TransactionType.income)
      .fold(0, (sum, tx) => sum + tx.amount);

  double get totalExpense => _transactions
      .where((tx) => tx.type == TransactionType.expense)
      .fold(0, (sum, tx) => sum + tx.amount);

  Future<void> addTransaction(String userId, TransactionModel transaction) async {
    await _service.addTransaction(userId, transaction);
  }

  Future<void> deleteTransaction(String userId, String transactionId) async {
    await _service.deleteTransaction(userId, transactionId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
