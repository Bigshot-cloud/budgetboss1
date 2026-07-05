import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsModel {
  final String id;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime targetDate;

  SavingsModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.savedAmount,
    required this.targetDate,
  });

  factory SavingsModel.fromMap(Map<String, dynamic> map, String id) {
    return SavingsModel(
      id: id,
      title: map['title'] ?? '',
      targetAmount: (map['targetAmount'] ?? 0).toDouble(),
      savedAmount: (map['savedAmount'] ?? 0).toDouble(),
      targetDate: (map['targetDate'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'targetDate': Timestamp.fromDate(targetDate),
    };
  }

  double get progress => targetAmount > 0 ? (savedAmount / targetAmount) : 0;
  bool get isCompleted => savedAmount >= targetAmount;
}
