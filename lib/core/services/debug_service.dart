import 'package:flutter/material.dart';

class DebugLog {
  final DateTime timestamp;
  final String feature;
  final String status;
  final String message;
  final String? details;

  DebugLog({
    required this.timestamp,
    required this.feature,
    required this.status,
    required this.message,
    this.details,
  });
}

class DebugService {
  static final DebugService _instance = DebugService._internal();
  factory DebugService() => _instance;
  DebugService._internal();

  final List<DebugLog> _logs = [];
  final int _maxLogs = 50;

  String _lastAiStatus = "Unknown";
  int? _lastResponseCode;

  void log({
    required String feature,
    required String status,
    required String message,
    String? details,
  }) {
    final newLog = DebugLog(
      timestamp: DateTime.now(),
      feature: feature,
      status: status,
      message: message,
      details: details,
    );

    _logs.insert(0, newLog);
    if (_logs.length > _maxLogs) {
      _logs.removeLast();
    }

    debugPrint("[$feature] $status: $message");
    if (details != null) debugPrint("Details: $details");
  }

  void updateAiStatus(String status, {int? responseCode}) {
    _lastAiStatus = status;
    _lastResponseCode = responseCode;
  }

  List<DebugLog> get logs => List.unmodifiable(_logs);
  String get lastAiStatus => _lastAiStatus;
  int? get lastResponseCode => _lastResponseCode;

  void clearLogs() {
    _logs.clear();
  }
}
