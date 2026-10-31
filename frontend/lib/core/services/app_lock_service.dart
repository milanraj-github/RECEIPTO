import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

final appLockServiceProvider = Provider<AppLockService>((ref) {
  return AppLockService(
    const FlutterSecureStorage(),
    LocalAuthentication(),
  );
});

class AppLockService {
  final FlutterSecureStorage _storage;
  final LocalAuthentication _localAuth;

  static const String _keyEnabled = 'app_lock_enabled';
  static const String _keyPinHash = 'pin_hash';
  static const String _keyBiometricEnabled = 'biometric_enabled';

  AppLockService(this._storage, this._localAuth);

  /// Checks if App Lock is enabled in secure storage. Default is false.
  Future<bool> isAppLockEnabled() async {
    try {
      final val = await _storage.read(key: _keyEnabled);
      return val == 'true';
    } catch (e) {
      if (kDebugMode) print('Error reading app_lock_enabled: $e');
      return false;
    }
  }

  /// Sets App Lock enabled state.
  Future<void> setAppLockEnabled(bool enabled) async {
    await _storage.write(key: _keyEnabled, value: enabled ? 'true' : 'false');
  }

  /// Checks if Biometric unlock is enabled.
  Future<bool> isBiometricEnabled() async {
    try {
      final val = await _storage.read(key: _keyBiometricEnabled);
      return val == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Sets Biometric unlock state.
  Future<void> setBiometricEnabled(bool enabled) async {
    await _storage.write(key: _keyBiometricEnabled, value: enabled ? 'true' : 'false');
  }

  /// Hashes a 4-digit PIN using SHA-256 and stores only the hash in secure storage.
  Future<void> setCustomPin(String pin) async {
    final bytes = utf8.encode(pin);
    final hash = sha256.convert(bytes).toString();
    await _storage.write(key: _keyPinHash, value: hash);
  }

  /// Verifies if the entered PIN matches the stored SHA-256 hash.
  Future<bool> verifyCustomPin(String enteredPin) async {
    try {
      final storedHash = await _storage.read(key: _keyPinHash);
      if (storedHash == null) return false;
      final bytes = utf8.encode(enteredPin);
      final enteredHash = sha256.convert(bytes).toString();
      return storedHash == enteredHash;
    } catch (e) {
      return false;
    }
  }

  /// Checks if a valid custom PIN hash is stored.
  Future<bool> isPinSet() async {
    try {
      final hash = await _storage.read(key: _keyPinHash);
      return hash != null && hash.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Purges all app lock configuration keys from secure storage to self-heal corrupted state.
  Future<void> resetAppLock() async {
    try {
      await _storage.delete(key: _keyEnabled);
      await _storage.delete(key: _keyPinHash);
      await _storage.delete(key: _keyBiometricEnabled);
    } catch (e) {
      if (kDebugMode) print('Error resetting app lock storage: $e');
    }
  }

  /// Checks if biometrics (fingerprint/face) are supported by the hardware and registered.
  Future<bool> isBiometricsAvailable() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isSupported = await _localAuth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (e) {
      return false;
    }
  }

  /// Authenticates using Fingerprint or Face Unlock ONLY (biometricOnly: true).
  /// NEVER invokes the native device PIN / Pattern / Password screen.
  Future<bool> authenticateBiometricsOnly({
    String reason = 'Scan fingerprint or face to unlock Receipto',
  }) async {
    try {
      final isAvailable = await isBiometricsAvailable();
      if (!isAvailable) return false;

      return await _localAuth.authenticate(
        localizedReason: reason,
        biometricOnly: true, // STRICT: Fingerprint / Face ONLY. No device credentials!
      );
    } on PlatformException catch (e) {
      if (kDebugMode) print('LocalAuthentication PlatformException: $e');
      return false;
    } catch (e) {
      if (kDebugMode) print('LocalAuthentication Error: $e');
      return false;
    }
  }
}
