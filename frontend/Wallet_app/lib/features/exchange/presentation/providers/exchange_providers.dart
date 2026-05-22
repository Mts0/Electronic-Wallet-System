import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/core/config/app_config.dart';
import 'package:y_wallet/core/providers/core_providers.dart';
import 'package:y_wallet/features/exchange/data/datasources/exchange_datasource.dart';
import 'package:y_wallet/features/exchange/data/datasources/exchange_mock_datasource.dart';
import 'package:y_wallet/features/exchange/data/datasources/exchange_remote_datasource.dart';
import 'package:y_wallet/features/exchange/data/repositories/exchange_repository_impl.dart';
import 'package:y_wallet/features/exchange/domain/repositories/exchange_repository.dart';

final exchangeDataSourceProvider = Provider<ExchangeDataSource>((ref) {
  if (AppConfig.useRemote) {
    final dio = ref.watch(dioProvider);
    return ExchangeRemoteDataSource(dio);
  }

  return ExchangeMockDataSource();
});

final exchangeRepositoryProvider = Provider<ExchangeRepository>((ref) {
  final dataSource = ref.watch(exchangeDataSourceProvider);
  return ExchangeRepositoryImpl(dataSource);
});
