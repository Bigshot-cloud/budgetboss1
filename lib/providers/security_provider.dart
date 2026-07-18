import 'dart:async';
import 'package:flutter/material.dart';
import '../core/services/security_service.dart';

class SecurityProvider with ChangeNotifier, WidgetsBindingObserver {
  final SecurityService _securityService = SecurityService();
  bool _isLocked = false;
  bool _isPinCreated = false;
  Timer? _autoLockTimer;
  Duration _lockDuration = const Duration(days: 365); // Default to Never
  String? _lastDurationStr;
  DateTime? _lastActiveTime;

  bool get isLocked => _isLocked;
  bool get isPinCreated => _isPinCreated;

  SecurityProvider() {
    _checkPinStatus();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoLockTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _lastActiveTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _checkAutoLockOnResume();
    }
  }

  void _checkAutoLockOnResume() {
    if (_lastActiveTime != null && _lockDuration != const Duration(days: 365)) {
      final inactiveDuration = DateTime.now().difference(_lastActiveTime!);
      if (inactiveDuration >= _lockDuration) {
        _isLocked = true;
        notifyListeners();
      }
    }
    resetTimer();
  }

  Future<void> _checkPinStatus() async {
    final pin = await _securityService.getPin();
    _isPinCreated = pin != null && pin.isNotEmpty;
    notifyListeners();
  }

  void syncSettings(Map<String, dynamic> settings) {
    final durationStr = settings['appLockDuration'] ?? 'Never';
    if (_lastDurationStr == durationStr) return;
    _lastDurationStr = durationStr;
    
    setLockDuration(durationStr);
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
        _lockDuration = const Duration(days: 365); // Never
    }
    resetTimer();
  }

  void resetTimer() {
    _autoLockTimer?.cancel();
    if (_lockDuration == const Duration(days: 365) || _isLocked) return;
    
    _autoLockTimer = Timer(_lockDuration, () {
      if (!_isLocked) {
        _isLocked = true;
        notifyListeners();
      }
    });
  }

  void unlock() {
    _isLocked = false;
    _lastActiveTime = DateTime.now();
    resetTimer();
    notifyListeners();
  }

  Future<void> updatePin(String newPin) async {
    await _securityService.setPin(newPin);
    _isPinCreated = true;
    notifyListeners();
  }

  Future<void> removePin() async {
    await _securityService.removePin();
    _isPinCreated = false;
    _isLocked = false;
    notifyListeners();
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
