import 'package:dio/dio.dart';
import 'package:y_wallet/features/transactions/data/datasources/transaction_datasource.dart';
import 'package:y_wallet/features/transactions/data/models/transaction_model.dart';

class TransactionRemoteDataSource implements TransactionDataSource {
  TransactionRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<List<TransactionModel>> getTransactions() async {
    final currenciesResponse = await _dio.get('/wallets/currencies');
    final transactionsResponse = await _dio.get(
      '/transactions/me',
      queryParameters: const {'limit': 50},
    );

    final currenciesMap = <int, String>{};
    final rawCurrencies = (currenciesResponse.data as List?) ?? const [];
    for (final item in rawCurrencies) {
      if (item is Map) {
        final json = Map<String, dynamic>.from(item);
        final id = ((json['currency_id'] ?? 0) as num).toInt();
        currenciesMap[id] = (json['symbol'] ?? '').toString();
      }
    }

    final rawTransactions = (transactionsResponse.data as List?) ?? const [];
    return rawTransactions
        .whereType<Map>()
        .map(
          (item) => TransactionModel.fromBackendJson(
            Map<String, dynamic>.from(item),
            currenciesMap: currenciesMap,
          ),
        )
        .toList();
  }
}
