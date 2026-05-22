import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/core/providers/core_providers.dart';
import 'package:y_wallet/features/splash/domain/entities/app_start_route.dart';
import 'package:y_wallet/features/splash/domain/services/app_startup_service.dart';

final appStartupServiceProvider = Provider<AppStartupService>((ref) {
  final sessionStorage = ref.watch(sessionStorageProvider);
  return AppStartupService(sessionStorage);
});

final appStartupProvider = FutureProvider<AppStartRoute>((ref) async {
  final service = ref.watch(appStartupServiceProvider);
  return service.resolveInitialRoute();
});