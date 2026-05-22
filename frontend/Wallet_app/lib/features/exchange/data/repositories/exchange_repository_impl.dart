import 'package:y_wallet/features/exchange/data/datasources/exchange_datasource.dart';
import 'package:y_wallet/features/exchange/data/mappers/exchange_mapper.dart';
import 'package:y_wallet/features/exchange/data/models/execute_exchange_request_model.dart';
import 'package:y_wallet/features/exchange/domain/entities/exchange_entity.dart';
import 'package:y_wallet/features/exchange/domain/entities/exchange_execution_result_entity.dart';
import 'package:y_wallet/features/exchange/domain/entities/exchange_quote_entity.dart';
import 'package:y_wallet/features/exchange/domain/repositories/exchange_repository.dart';

class ExchangeRepositoryImpl implements ExchangeRepository {
  ExchangeRepositoryImpl(this._dataSource);

  final ExchangeDataSource _dataSource;

  @override
  Future<ExchangeQuoteEntity> getPairRate({
    required String baseCurrency,
    required String targetCurrency,
  }) async {
    final response = await _dataSource.getPairRate(
      baseCurrency: baseCurrency,
      targetCurrency: targetCurrency,
    );
    return response.toEntity();
  }

  @override
  Future<ExchangeExecutionResultEntity> executeExchange({
    required ExchangeEntity exchange,
  }) async {
    final request = ExecuteExchangeRequestModel(
      fromAccountId: exchange.fromAccountId,
      toAccountId: exchange.toAccountId,
      fromAmount: exchange.fromAmount,
      notes: exchange.notes,
    );

    final response = await _dataSource.executeExchange(request);
    return response.toEntity();
  }
}
