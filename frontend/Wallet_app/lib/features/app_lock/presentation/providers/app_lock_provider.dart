import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/core/providers/core_providers.dart';
import 'package:y_wallet/features/app_lock/domain/services/app_lock_service.dart';
import 'package:y_wallet/features/app_lock/domain/services/biometric_service.dart';

final appLockServiceProvider = Provider<AppLockService>((ref) {
  final sessionStorage = ref.watch(sessionStorageProvider);
  return AppLockService(sessionStorage);
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final appUnlockedProvider = StateProvider<bool>((ref) => false);