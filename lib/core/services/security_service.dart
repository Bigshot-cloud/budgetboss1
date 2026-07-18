import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );
  final _localAuth = LocalAuthentication();

  Future<void> setPin(String pin) async {
    await _storage.write(key: 'user_pin', value: pin);
  }

  Future<String?> getPin() async {
    try {
      return await _storage.read(key: 'user_pin');
    } catch (e) {
      // If decryption fails (common on Android after reinstall/re-sign), clear and return null
      await _storage.deleteAll();
      return null;
    }
  }

  Future<bool> verifyPin(String pin) async {
    final storedPin = await getPin();
    return storedPin == pin;
  }

  Future<void> removePin() async {
    await _storage.delete(key: 'user_pin');
  }

  Future<bool> canCheckBiometrics() async {
    try {
      return await _localAuth.canCheckBiometrics || await _localAuth.isDeviceSupported();
    } catch (e) {
      return false;
    }
  }

  Future<bool> authenticateWithBiometrics() async {
    try {
      final bool isAvailable =
          await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();

      if (!isAvailable) return false;

      // Using only required parameter to maximize compatibility across versions
      return await _localAuth.authenticate(
        localizedReason: 'Authenticate to access BudgetBoss',
      );
    } catch (e) {
      return false;
    }
  }
}
