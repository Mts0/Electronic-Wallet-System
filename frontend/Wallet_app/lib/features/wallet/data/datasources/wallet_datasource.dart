import 'package:y_wallet/features/wallet/data/models/wallet_model.dart';

abstract class WalletDataSource {
  Future<WalletModel> getWallet();
}