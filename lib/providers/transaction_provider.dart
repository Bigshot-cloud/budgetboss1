import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/transaction_service.dart';
import '../models/transaction.dart';

class TransactionProvider with ChangeNotifier {
  final TransactionService _service = TransactionService();
  List<TransactionModel> _transactions = [];
  StreamSubscription? _subscription;
  String? _currentUserId;

  List<TransactionModel> get transactions => [..._transactions];

  List<TransactionModel> get recentTransactions {
    return _transactions.take(5).toList();
  }

  void setUser(String? userId) {
    if (_currentUserId == userId) return;
    _currentUserId = userId;

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
    double income = totalIncome;
    double expense = totalExpense;
    return income - expense;
  }

  double get totalIncome => _transactions
      .where((tx) => tx.type == TransactionType.income)
      .fold(0, (sum, tx) => sum + tx.amount);

  double get totalExpense => _transactions
      .where((tx) => tx.type == TransactionType.expense)
      .fold(0, (sum, tx) => sum + tx.amount);

  double get monthlyExpense {
    final now = DateTime.now();
    return _transactions
        .where((tx) => tx.type == TransactionType.expense && tx.date.month == now.month && tx.date.year == now.year)
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  double get monthlyIncome {
    final now = DateTime.now();
    return _transactions
        .where((tx) => tx.type == TransactionType.income && tx.date.month == now.month && tx.date.year == now.year)
        .fold(0, (sum, tx) => sum + tx.amount);
  }

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
