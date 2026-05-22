import 'package:y_wallet/features/transactions/data/datasources/transaction_datasource.dart';
import 'package:y_wallet/features/transactions/data/mappers/transaction_mapper.dart';
import 'package:y_wallet/features/transactions/domain/entities/transaction_entity.dart';
import 'package:y_wallet/features/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionDataSource _dataSource;

  TransactionRepositoryImpl(this._dataSource);

  @override
  Future<List<TransactionEntity>> getTransactions() async {
    final models = await _dataSource.getTransactions();
    return models.map((item) => item.toEntity()).toList();
  }
}