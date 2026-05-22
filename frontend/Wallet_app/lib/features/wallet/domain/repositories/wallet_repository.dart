import 'package:y_wallet/features/wallet/domain/entities/wallet_entity.dart';

abstract class WalletRepository {
  Future<WalletEntity> getWallet();
}