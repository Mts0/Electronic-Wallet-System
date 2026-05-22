import 'package:y_wallet/features/exchange/data/models/execute_exchange_response_model.dart';
import 'package:y_wallet/features/exchange/data/models/exchange_quote_response_model.dart';
import 'package:y_wallet/features/exchange/domain/entities/exchange_execution_result_entity.dart';
import 'package:y_wallet/features/exchange/domain/entities/exchange_quote_entity.dart';

extension ExchangeQuoteResponseModelMapper on ExchangeQuoteResponseModel {
  ExchangeQuoteEntity toEntity() {
    return ExchangeQuoteEntity(
      baseCurrency: baseCurrency,
      targetCurrency: targetCurrency,
      rateValue: rateValue,
      updatedAt: updatedAtIso == null ? null : DateTime.tryParse(updatedAtIso!),
    );
  }
}

extension ExecuteExchangeResponseModelMapper on ExecuteExchangeResponseModel {
  ExchangeExecutionResultEntity toEntity() {
    return ExchangeExecutionResultEntity(
      status: _mapStatus(status),
      transactionId: transactionId,
      reference: reference,
      message: message,
      toAmount: toAmount,
      exchangeRate: exchangeRate,
    );
  }
}

ExchangeExecutionResultStatus _mapStatus(String value) {
  switch (value) {
    case 'pending':
      return ExchangeExecutionResultStatus.pending;
    case 'failed':
      return ExchangeExecutionResultStatus.failed;
    case 'success':
    default:
      return ExchangeExecutionResultStatus.success;
  }
}
