import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:y_wallet/core/constants/storage_keys.dart';

class SessionStorage {
  SessionStorage(this._storage);

  final FlutterSecureStorage _storage;

  Future<void> saveAccessToken(String token) async {
    await _storage.write(
      key: StorageKeys.accessToken,
      value: token,
    );
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: StorageKeys.accessToken);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(
      key: StorageKeys.refreshToken,
      value: token,
    );
  }

  Future<String?> getRefreshToken() async {
    return _storage.read(key: StorageKeys.refreshToken);
  }

  Future<void> saveCurrentUserPhone(String phone) async {
    await _storage.write(
      key: StorageKeys.currentUserPhone,
      value: phone,
    );
  }

  Future<String?> getCurrentUserPhone() async {
    return _storage.read(key: StorageKeys.currentUserPhone);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: StorageKeys.accessToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.currentUserPhone);
  }

  Future<bool> hasSession() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> setAppLockEnabled(bool value) async {
    await _storage.write(
      key: StorageKeys.appLockEnabled,
      value: value.toString(),
    );
  }

  Future<bool> isAppLockEnabled() async {
    final value = await _storage.read(key: StorageKeys.appLockEnabled);
    return value == 'true';
  }

  Future<void> setBiometricEnabled(bool value) async {
    await _storage.write(
      key: StorageKeys.biometricEnabled,
      value: value.toString(),
    );
  }

  Future<bool> isBiometricEnabled() async {
    final value = await _storage.read(key: StorageKeys.biometricEnabled);
    return value == 'true';
  }

  Future<void> savePinCode(String pin) async {
    await _storage.write(
      key: StorageKeys.pinCode,
      value: pin,
    );
  }

  Future<String?> getPinCode() async {
    return _storage.read(key: StorageKeys.pinCode);
  }

  Future<bool> hasPinCode() async {
    final pin = await getPinCode();
    return pin != null && pin.isNotEmpty;
  }

  Future<void> clearPinCode() async {
    await _storage.delete(key: StorageKeys.pinCode);
  }

  Future<void> clearSecurityLock() async {
    await _storage.delete(key: StorageKeys.pinCode);
    await _storage.delete(key: StorageKeys.appLockEnabled);
    await _storage.delete(key: StorageKeys.biometricEnabled);
  }

  Future<void> clearAll() async {
    await clearSession();
    await clearSecurityLock();
  }
}