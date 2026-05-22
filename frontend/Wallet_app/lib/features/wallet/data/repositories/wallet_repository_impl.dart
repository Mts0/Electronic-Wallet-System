import 'package:y_wallet/features/wallet/data/datasources/wallet_datasource.dart';
import 'package:y_wallet/features/wallet/data/mappers/wallet_mapper.dart';
import 'package:y_wallet/features/wallet/domain/entities/wallet_entity.dart';
import 'package:y_wallet/features/wallet/domain/repositories/wallet_repository.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletDataSource _dataSource;

  WalletRepositoryImpl(this._dataSource);

  @override
  Future<WalletEntity> getWallet() async {
    final model = await _dataSource.getWallet();
    return model.toEntity();
  }
}