import 'package:y_wallet/features/transactions/data/models/transaction_model.dart';

abstract class TransactionDataSource {
  Future<List<TransactionModel>> getTransactions();
}