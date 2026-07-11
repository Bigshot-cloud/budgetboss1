import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum TransactionType { income, expense, transfer }

class TransactionModel {
  final String id;
  final String title;
  final double amount;
  final DateTime date;
  final String category;
  final TransactionType type;
  final IconData icon;

  TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.type,
    required this.icon,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    final category = (map['category'] ?? '').toString();

    DateTime parsedDate;
    if (map['date'] is Timestamp) {
      parsedDate = (map['date'] as Timestamp).toDate();
    } else {
      parsedDate = DateTime.now();
    }

    return TransactionModel(
      id: id,
      title: (map['title'] ?? '').toString(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: parsedDate,
      category: category,
      type: TransactionType.values.firstWhere(
            (e) => e.toString() == map['type'],
        orElse: () => TransactionType.expense,
      ),
      icon: _getCategoryIcon(category),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'category': category,
      'type': type.toString(),
    };
  }

  static IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
        return Icons.restaurant;

      case 'transport':
        return Icons.directions_car;

      case 'shopping':
        return Icons.shopping_bag;

      case 'salary':
      case 'income':
        return Icons.account_balance_wallet;

      case 'bills':
        return Icons.receipt_long;

      case 'health':
        return Icons.local_hospital;

      case 'education':
        return Icons.school;

      case 'entertainment':
        return Icons.movie;

      case 'savings':
        return Icons.savings;

      default:
        return Icons.help_outline;
    }
  }
}
