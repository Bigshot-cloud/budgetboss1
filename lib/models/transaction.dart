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
    final typeString = (map['type'] ?? '').toString().toLowerCase();

    TransactionType parsedType;
    if (typeString.contains('income')) {
      parsedType = TransactionType.income;
    } else if (typeString.contains('transfer')) {
      parsedType = TransactionType.transfer;
    } else {
      parsedType = TransactionType.expense;
    }

    DateTime parsedDate;
    if (map['date'] is Timestamp) {
      parsedDate = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is String) {
      parsedDate = DateTime.tryParse(map['date']) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return TransactionModel(
      id: id,
      title: (map['title'] ?? '').toString(),
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      date: parsedDate,
      category: category,
      type: parsedType,
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
      case 'food & dining':
        return Icons.restaurant;

      case 'transport':
      case 'transportation':
        return Icons.directions_car;

      case 'shopping':
        return Icons.shopping_bag;

      case 'salary':
      case 'income':
        return Icons.account_balance_wallet;

      case 'bills':
      case 'utilities':
        return Icons.receipt_long;

      case 'health':
      case 'healthcare':
        return Icons.local_hospital;

      case 'education':
        return Icons.school;

      case 'entertainment':
        return Icons.movie;

      case 'savings':
        return Icons.savings;
        
      case 'investment':
        return Icons.trending_up;
        
      case 'transfers':
        return Icons.compare_arrows;

      case 'mobile money':
        return Icons.phone_android;

      case 'bank deposit':
        return Icons.account_balance;

      case 'atm withdrawal':
        return Icons.atm;

      default:
        return Icons.help_outline;
    }
  }
}
