import 'dart:async';

import 'package:y_wallet/core/errors/app_exception.dart';
import 'package:y_wallet/features/exchange/data/datasources/exchange_datasource.dart';
import 'package:y_wallet/features/exchange/data/models/execute_exchange_request_model.dart';
import 'package:y_wallet/features/exchange/data/models/execute_exchange_response_model.dart';
import 'package:y_wallet/features/exchange/data/models/exchange_quote_response_model.dart';

class ExchangeMockDataSource implements ExchangeDataSource {
  static const Map<String, double> _rates = {
    'YER:USD': 0.0040,
    'USD:YER': 250.0,
    'YER:SAR': 0.0150,
    'SAR:YER': 66.6667,
    'USD:SAR': 3.75,
    'SAR:USD': 0.2667,
  };

  @override
  Future<ExchangeQuoteResponseModel> getPairRate({
    required String baseCurrency,
    required String targetCurrency,
  }) async {
    await Future.delayed(const Duration(milliseconds: 450));

    final key = '${baseCurrency.trim().toUpperCase()}:${targetCurrency.trim().toUpperCase()}';

    if (key.endsWith('401')) {
      throw AppException.sessionExpired();
    }

    final rate = _rates[key];
    if (rate == null) {
      throw AppException.server('سعر الصرف غير متوفر لهذا الزوج');
    }

    return ExchangeQuoteResponseModel(
      baseCurrency: baseCurrency.trim().toUpperCase(),
      targetCurrency: targetCurrency.trim().toUpperCase(),
      rateValue: rate,
      updatedAtIso: DateTime.now().toIso8601String(),
    );
  }

  @override
  Future<ExecuteExchangeResponseModel> executeExchange(
    ExecuteExchangeRequestModel request,
  ) async {
    await Future.delayed(const Duration(milliseconds: 850));

    if (request.fromAmount <= 0) {
      return const ExecuteExchangeResponseModel(
        status: 'failed',
        message: 'المبلغ غير صحيح',
      );
    }

    if (request.fromAmount >= 5000 && request.fromAmount < 10000) {
      return ExecuteExchangeResponseModel(
        status: 'pending',
        transactionId: 'tx_${DateTime.now().millisecondsSinceEpoch}',
        reference: 'EXC-${DateTime.now().millisecondsSinceEpoch}',
        message: 'عملية المصارفة قيد المراجعة',
      );
    }

    return ExecuteExchangeResponseModel(
      status: 'success',
      transactionId: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      reference: 'EXC-${DateTime.now().millisecondsSinceEpoch}',
      message: 'تم تنفيذ المصارفة بنجاح',
    );
  }
}
