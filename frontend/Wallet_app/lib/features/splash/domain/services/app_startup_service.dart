import 'package:y_wallet/core/storage/session_storage.dart';
import 'package:y_wallet/features/splash/domain/entities/app_start_route.dart';

class AppStartupService {
  AppStartupService(this._sessionStorage);

  final SessionStorage _sessionStorage;

  Future<AppStartRoute> resolveInitialRoute() async {
    final hasSession = await _sessionStorage.hasSession();

    if (!hasSession) {
      return AppStartRoute.login;
    }

    final appLockEnabled = await _sessionStorage.isAppLockEnabled();
    final hasPin = await _sessionStorage.hasPinCode();

    if (appLockEnabled && hasPin) {
      return AppStartRoute.appLock;
    }

    return AppStartRoute.home;
  }
}