import 'package:dio/dio.dart';
import 'package:y_wallet/features/wallet/data/datasources/wallet_datasource.dart';
import 'package:y_wallet/features/wallet/data/models/wallet_model.dart';

class WalletRemoteDataSource implements WalletDataSource {
  WalletRemoteDataSource(this._dio);

  final Dio _dio;

  @override
  Future<WalletModel> getWallet() async {
    final response = await _dio.get('/wallets/me');
    final body = response.data;

    if (body is Map<String, dynamic>) {
      return WalletModel.fromJson(body);
    }
    if (body is Map) {
      return WalletModel.fromJson(Map<String, dynamic>.from(body));
    }

    throw Exception('استجابة المحفظة غير صالحة');
  }
}
