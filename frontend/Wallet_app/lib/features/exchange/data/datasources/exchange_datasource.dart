import 'package:y_wallet/features/exchange/data/models/execute_exchange_request_model.dart';
import 'package:y_wallet/features/exchange/data/models/execute_exchange_response_model.dart';
import 'package:y_wallet/features/exchange/data/models/exchange_quote_response_model.dart';

abstract class ExchangeDataSource {
  Future<ExchangeQuoteResponseModel> getPairRate({
    required String baseCurrency,
    required String targetCurrency,
  });

  Future<ExecuteExchangeResponseModel> executeExchange(
    ExecuteExchangeRequestModel request,
  );
}
