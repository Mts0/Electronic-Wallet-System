import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/features/transactions/domain/entities/transaction_entity.dart';

final transactionStoreProvider =
StateNotifierProvider<TransactionStore, List<TransactionEntity>>((ref) {
  return TransactionStore();
});

class TransactionStore extends StateNotifier<List<TransactionEntity>> {
  TransactionStore() : super(const []);

  void setInitial(List<TransactionEntity> items) {
    if (state.isEmpty) {
      state = items;
    }
  }

  void addTransaction(TransactionEntity item) {
    state = [item, ...state];
  }

  void reset(List<TransactionEntity> items) {
    state = items;
  }
}