import 'package:y_wallet/features/exchange/domain/entities/exchange_entity.dart';
import 'package:y_wallet/features/exchange/domain/entities/exchange_execution_result_entity.dart';
import 'package:y_wallet/features/exchange/domain/entities/exchange_quote_entity.dart';

abstract class ExchangeRepository {
  Future<ExchangeQuoteEntity> getPairRate({
    required String baseCurrency,
    required String targetCurrency,
  });

  Future<ExchangeExecutionResultEntity> executeExchange({
    required ExchangeEntity exchange,
  });
}
