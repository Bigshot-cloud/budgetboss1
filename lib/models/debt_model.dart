import 'package:cloud_firestore/cloud_firestore.dart';

class DebtModel {
  final String id;
  final String title;
  final double amount;
  final double paidAmount;
  final DateTime dueDate;
  final bool isPaid;

  DebtModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.paidAmount,
    required this.dueDate,
    this.isPaid = false,
  });

  factory DebtModel.fromMap(Map<String, dynamic> map, String id) {
    return DebtModel(
      id: id,
      title: map['title'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      paidAmount: (map['paidAmount'] ?? 0).toDouble(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      isPaid: map['isPaid'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'amount': amount,
      'paidAmount': paidAmount,
      'dueDate': Timestamp.fromDate(dueDate),
      'isPaid': isPaid,
    };
  }

  double get progress => amount > 0 ? (paidAmount / amount) : 0;
}
