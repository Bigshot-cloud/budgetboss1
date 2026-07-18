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
    return _transactions.take(10).toList(); // Show more in recent list for better demo
  }

  void setUser(String? userId) {
    if (_currentUserId == userId) return;
    debugPrint('TransactionProvider: Setting user to $userId');
    _currentUserId = userId;

    _subscription?.cancel();
    if (userId != null) {
      _subscription = _service.getTransactionsStream(userId).listen((data) {
        debugPrint('TransactionProvider: Received ${data.length} transactions from Firestore');
        _transactions = data;
        notifyListeners();
      }, onError: (e) {
        debugPrint('TransactionProvider: Error in stream: $e');
      });
    } else {
      _transactions = [];
      notifyListeners();
    }
  }

  double get totalBalance {
    return totalIncome - totalExpense;
  }

  double get totalIncome => _transactions
      .where((tx) => tx.type == TransactionType.income)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get totalExpense => _transactions
      .where((tx) => tx.type == TransactionType.expense)
      .fold(0.0, (sum, tx) => sum + tx.amount);

  double get monthlyExpense {
    final now = DateTime.now();
    return _transactions
        .where((tx) => tx.type == TransactionType.expense && tx.date.month == now.month && tx.date.year == now.year)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  double get monthlyIncome {
    final now = DateTime.now();
    return _transactions
        .where((tx) => tx.type == TransactionType.income && tx.date.month == now.month && tx.date.year == now.year)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  Future<void> addTransaction(String userId, TransactionModel transaction) async {
    debugPrint('TransactionProvider: Adding transaction ${transaction.title}');
    try {
      await _service.addTransaction(userId, transaction);
      debugPrint('TransactionProvider: Transaction saved successfully');
    } catch (e) {
      debugPrint('TransactionProvider: Failed to add transaction: $e');
      rethrow;
    }
  }

  Future<void> deleteTransaction(String userId, String transactionId) async {
    debugPrint('TransactionProvider: Deleting transaction $transactionId');
    try {
      await _service.deleteTransaction(userId, transactionId);
      debugPrint('TransactionProvider: Transaction deleted successfully');
    } catch (e) {
      debugPrint('TransactionProvider: Failed to delete transaction: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
