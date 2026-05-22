import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/core/config/app_config.dart';
import 'package:y_wallet/core/providers/core_providers.dart';
import 'package:y_wallet/features/transactions/data/datasources/transaction_datasource.dart';
import 'package:y_wallet/features/transactions/data/datasources/transaction_mock_datasource.dart';
import 'package:y_wallet/features/transactions/data/datasources/transaction_remote_datasource.dart';
import 'package:y_wallet/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:y_wallet/features/transactions/domain/entities/transaction_entity.dart';
import 'package:y_wallet/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:y_wallet/features/transactions/presentation/controllers/transaction_store.dart';

enum TransactionFilter {
  all,
  incoming,
  outgoing,
}

final transactionDataSourceProvider = Provider<TransactionDataSource>((ref) {
  if (AppConfig.useRemote) {
    final dio = ref.watch(dioProvider);
    return TransactionRemoteDataSource(dio);
  }
  return TransactionMockDataSource();
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final dataSource = ref.watch(transactionDataSourceProvider);
  return TransactionRepositoryImpl(dataSource);
});

final transactionControllerProvider = StateNotifierProvider<
    TransactionController,
    AsyncValue<List<TransactionEntity>>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionController(ref, repository);
});

final transactionFilterProvider =
    StateProvider<TransactionFilter>((ref) => TransactionFilter.all);

class TransactionController
    extends StateNotifier<AsyncValue<List<TransactionEntity>>> {
  TransactionController(this._ref, this._repository)
      : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  final Ref _ref;
  final TransactionRepository _repository;

  Future<void> loadTransactions() async {
    state = const AsyncValue.loading();

    try {
      final transactions = await _repository.getTransactions();
      _ref.read(transactionStoreProvider.notifier).reset(transactions);
      state = AsyncValue.data(transactions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void syncFromStore() {
    final current = _ref.read(transactionStoreProvider);
    state = AsyncValue.data(current);
  }
}
