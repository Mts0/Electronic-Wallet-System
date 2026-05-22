import 'dart:async';

import 'package:y_wallet/features/transactions/data/datasources/transaction_datasource.dart';
import 'package:y_wallet/features/transactions/data/models/transaction_model.dart';

class TransactionMockDataSource implements TransactionDataSource {
  @override
  Future<List<TransactionModel>> getTransactions() async {
    await Future.delayed(const Duration(milliseconds: 400));

    return const [
      TransactionModel(
        id: 'tx_001',
        title: 'تحويل مالي',
        description: 'تحويل إلى أحمد علي',
        amount: 12450.75,
        currencyCode: 'SAR',
        createdAtIso: '2026-03-14T10:15:00',
        status: 'success',
        direction: 'outgoing',
        reference: 'REF-1001',
      ),
      TransactionModel(
        id: 'tx_002',
        title: 'استلام حوالة',
        description: 'حوالة واردة من محمد سعيد',
        amount: 3800.00,
        currencyCode: 'SAR',
        createdAtIso: '2026-03-14T08:40:00',
        status: 'success',
        direction: 'incoming',
        reference: 'REF-1002',
      ),
      TransactionModel(
        id: 'tx_003',
        title: 'شراء أونلاين',
        description: 'دفع متجر إلكتروني',
        amount: 59.99,
        currencyCode: 'USD',
        createdAtIso: '2026-03-13T21:25:00',
        status: 'success',
        direction: 'outgoing',
        reference: 'REF-1003',
      ),
      TransactionModel(
        id: 'tx_004',
        title: 'سحب نقدي',
        description: 'سحب من وكيل معتمد',
        amount: 25000.00,
        currencyCode: 'YER',
        createdAtIso: '2026-03-13T16:10:00',
        status: 'pending',
        direction: 'outgoing',
        reference: 'REF-1004',
      ),
      TransactionModel(
        id: 'tx_005',
        title: 'شحن وسداد',
        description: 'سداد فاتورة خدمات',
        amount: 7800.00,
        currencyCode: 'YER',
        createdAtIso: '2026-03-12T19:45:00',
        status: 'success',
        direction: 'outgoing',
        reference: 'REF-1005',
      ),
      TransactionModel(
        id: 'tx_006',
        title: 'إيداع',
        description: 'إيداع إلى الحساب الرئيسي',
        amount: 1200.00,
        currencyCode: 'USD',
        createdAtIso: '2026-03-12T11:05:00',
        status: 'failed',
        direction: 'incoming',
        reference: 'REF-1006',
      ),
    ];
  }
}