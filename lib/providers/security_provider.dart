import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/security_service.dart';

class SecurityProvider with ChangeNotifier {
  final SecurityService _securityService = SecurityService();
  bool _isLocked = false;
  bool _isPinCreated = false;
  Timer? _autoLockTimer;
  Duration _lockDuration = Duration.zero;

  bool get isLocked => _isLocked;
  bool get isPinCreated => _isPinCreated;

  SecurityProvider() {
    _checkPinStatus();
  }

  Future<void> _checkPinStatus() async {
    final pin = await _securityService.getPin();
    _isPinCreated = pin != null && pin.isNotEmpty;
    notifyListeners();
  }

  void setLockDuration(String durationStr) {
    switch (durationStr) {
      case 'Immediately':
        _lockDuration = Duration.zero;
        break;
      case '30 seconds':
        _lockDuration = const Duration(seconds: 30);
        break;
      case '1 minute':
        _lockDuration = const Duration(minutes: 1);
        break;
      case '5 minutes':
        _lockDuration = const Duration(minutes: 5);
        break;
      case '10 minutes':
        _lockDuration = const Duration(minutes: 10);
        break;
      default:
        _lockDuration = const Duration(days: 365); // Never effectively
    }
    resetTimer();
  }

  void resetTimer() {
    _autoLockTimer?.cancel();
    if (_lockDuration == const Duration(days: 365)) return;
    
    _autoLockTimer = Timer(_lockDuration, () {
      _isLocked = true;
      notifyListeners();
    });
  }

  void unlock() {
    _isLocked = false;
    resetTimer();
    notifyListeners();
  }

  Future<void> updatePin(String newPin) async {
    await _securityService.setPin(newPin);
    _isPinCreated = true;
    notifyListeners();
  }

  void syncSettings(Map<String, dynamic> settings) {
    final duration = settings['appLockDuration'] ?? 'Never';
    setLockDuration(duration);
  }

  Future<bool> verifyPin(String pin) async {
    return await _securityService.verifyPin(pin);
  }

  Future<bool> authenticateBiometrics() async {
    final success = await _securityService.authenticateWithBiometrics();
    if (success) {
      unlock();
    }
    return success;
  }
}
