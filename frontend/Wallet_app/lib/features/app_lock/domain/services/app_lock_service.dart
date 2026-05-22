import 'package:y_wallet/core/storage/session_storage.dart';

class AppLockService {
  AppLockService(this._sessionStorage);

  final SessionStorage _sessionStorage;

  Future<void> savePin(String pin) async {
    await _sessionStorage.savePinCode(pin);
    await _sessionStorage.setAppLockEnabled(true);
  }

  Future<bool> validatePin(String pin) async {
    final savedPin = await _sessionStorage.getPinCode();
    return savedPin == pin;
  }

  Future<bool> hasPin() async {
    return _sessionStorage.hasPinCode();
  }

  Future<void> disableAppLock() async {
    await _sessionStorage.clearPinCode();
    await _sessionStorage.setAppLockEnabled(false);
  }
}