import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/core/config/app_config.dart';
import 'package:y_wallet/core/providers/core_providers.dart';
import 'package:y_wallet/features/transfer/data/datasources/transfer_datasource.dart';
import 'package:y_wallet/features/transfer/data/datasources/transfer_mock_datasource.dart';
import 'package:y_wallet/features/transfer/data/datasources/transfer_remote_datasource.dart';
import 'package:y_wallet/features/transfer/data/repositories/transfer_repository_impl.dart';
import 'package:y_wallet/features/transfer/domain/repositories/transfer_repository.dart';

final transferDataSourceProvider = Provider<TransferDataSource>((ref) {
  if (AppConfig.useRemote) {
    final dio = ref.watch(dioProvider);
    return TransferRemoteDataSource(dio);
  }

  return TransferMockDataSource();
});

final transferRepositoryProvider = Provider<TransferRepository>((ref) {
  final dataSource = ref.watch(transferDataSourceProvider);
  return TransferRepositoryImpl(dataSource);
});
