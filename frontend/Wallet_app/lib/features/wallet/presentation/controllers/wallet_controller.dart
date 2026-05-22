import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/core/config/app_config.dart';
import 'package:y_wallet/core/providers/core_providers.dart';
import 'package:y_wallet/features/wallet/data/datasources/wallet_datasource.dart';
import 'package:y_wallet/features/wallet/data/datasources/wallet_mock_datasource.dart';
import 'package:y_wallet/features/wallet/data/datasources/wallet_remote_datasource.dart';
import 'package:y_wallet/features/wallet/data/repositories/wallet_repository_impl.dart';
import 'package:y_wallet/features/wallet/domain/entities/wallet_account_entity.dart';
import 'package:y_wallet/features/wallet/domain/entities/wallet_entity.dart';
import 'package:y_wallet/features/wallet/domain/repositories/wallet_repository.dart';

final walletDataSourceProvider = Provider<WalletDataSource>((ref) {
  if (AppConfig.useRemote) {
    final dio = ref.watch(dioProvider);
    return WalletRemoteDataSource(dio);
  }
  return WalletMockDataSource();
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  final dataSource = ref.watch(walletDataSourceProvider);
  return WalletRepositoryImpl(dataSource);
});

final walletControllerProvider =
    StateNotifierProvider<WalletController, AsyncValue<WalletEntity>>((ref) {
  final repository = ref.watch(walletRepositoryProvider);
  return WalletController(repository);
});

final walletBalanceVisibleProvider = StateProvider<bool>((ref) => true);

final walletCarouselIndexProvider = StateProvider<int>((ref) => 0);

class WalletController extends StateNotifier<AsyncValue<WalletEntity>> {
  WalletController(this._repository) : super(const AsyncValue.loading()) {
    loadWallet();
  }

  final WalletRepository _repository;

  Future<void> loadWallet() async {
    state = const AsyncValue.loading();

    try {
      final wallet = await _repository.getWallet();
      state = AsyncValue.data(wallet);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void deductBalanceFromSelectedAccount({
    required int accountId,
    required double amount,
  }) {
    final currentWallet = state.value;
    if (currentWallet == null) return;

    final updatedAccounts = <WalletAccountEntity>[];

    for (final account in currentWallet.accounts) {
      if (account.id != accountId) {
        updatedAccounts.add(account);
        continue;
      }

      final newBalance = account.balance - amount;
      updatedAccounts.add(
        account.copyWith(
          balance: newBalance < 0 ? 0 : newBalance,
        ),
      );
    }

    state = AsyncValue.data(
      currentWallet.copyWith(accounts: updatedAccounts),
    );
  }
}
