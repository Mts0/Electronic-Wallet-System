import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/core/providers/core_providers.dart';
import 'package:y_wallet/core/storage/session_storage.dart';
import 'package:y_wallet/features/auth/data/datasources/auth_datasource.dart';
import 'package:y_wallet/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:y_wallet/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:y_wallet/features/auth/domain/entities/auth_session_entity.dart';
import 'package:y_wallet/features/auth/domain/repositories/auth_repository.dart';

final authDataSourceProvider = Provider<AuthDataSource>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRemoteDataSource(dio);
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authDataSourceProvider);
  return AuthRepositoryImpl(dataSource);
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthSessionEntity?>>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  final sessionStorage = ref.watch(sessionStorageProvider);
  return AuthController(repository, sessionStorage);
});

class AuthController extends StateNotifier<AsyncValue<AuthSessionEntity?>> {
  AuthController(this._repository, this._sessionStorage)
      : super(const AsyncValue.loading()) {
    _restoreSession();
  }

  final AuthRepository _repository;
  final SessionStorage _sessionStorage;

  Future<void> _restoreSession() async {
    try {
      final hasSession = await _sessionStorage.hasSession();
      if (!hasSession) {
        state = const AsyncValue.data(null);
        return;
      }

      final user = await _repository.getMe();
      final accessToken = await _sessionStorage.getAccessToken() ?? '';
      final refreshToken = await _sessionStorage.getRefreshToken();

      state = AsyncValue.data(
        AuthSessionEntity(
          accessToken: accessToken,
          refreshToken: refreshToken,
          user: user,
        ),
      );
    } catch (_) {
      await _sessionStorage.clearSession();
      state = const AsyncValue.data(null);
    }
  }

  Future<void> login({
    required String phoneNumber,
    required String password,
  }) async {
    state = const AsyncValue.loading();

    try {
      final session = await _repository.login(
        phoneNumber: phoneNumber,
        password: password,
      );

      await _sessionStorage.saveAccessToken(session.accessToken);

      if (session.refreshToken != null && session.refreshToken!.isNotEmpty) {
        await _sessionStorage.saveRefreshToken(session.refreshToken!);
      }

      await _sessionStorage.saveCurrentUserPhone(session.user.phoneNumber);

      state = AsyncValue.data(session);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    try {
      await _repository.logout();
    } catch (_) {
      // ignore logout transport/server errors
    }

    await _sessionStorage.clearSession();
    state = const AsyncValue.data(null);
  }
}
