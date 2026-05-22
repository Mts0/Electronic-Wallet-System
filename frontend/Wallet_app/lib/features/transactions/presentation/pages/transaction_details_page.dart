import 'package:flutter/material.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/features/transactions/domain/entities/transaction_entity.dart';

class TransactionDetailsPage extends StatelessWidget {
  const TransactionDetailsPage({
    super.key,
    required this.transaction,
  });

  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(transaction.status);
    final directionColor = transaction.direction == TransactionDirection.incoming
        ? AppColors.success
        : AppColors.primary;

    final amountPrefix =
    transaction.direction == TransactionDirection.incoming ? '+' : '-';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF090F1E),
              Color(0xFF0A1122),
              Color(0xFF0B1020),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'تفاصيل العملية',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                decoration: BoxDecoration(
                  color: const Color(0xFF12192B).withOpacity(0.98),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: directionColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(
                        transaction.direction == TransactionDirection.incoming
                            ? Icons.call_received_rounded
                            : Icons.call_made_rounded,
                        color: directionColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      transaction.title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$amountPrefix ${_formatAmount(transaction.amount)} ${transaction.currencyCode}',
                      style: TextStyle(
                        color: directionColor,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Text(
                        _statusText(transaction.status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _DetailsSection(
                title: 'معلومات العملية',
                children: [
                  _DetailRow(
                    label: 'الوصف',
                    value: transaction.description,
                  ),
                  _DetailRow(
                    label: 'العملة',
                    value: transaction.currencyCode,
                  ),
                  _DetailRow(
                    label: 'الاتجاه',
                    value: transaction.direction == TransactionDirection.incoming
                        ? 'وارد'
                        : 'صادر',
                  ),
                  _DetailRow(
                    label: 'التاريخ',
                    value: _formatDateTime(transaction.createdAt),
                  ),
                  _DetailRow(
                    label: 'المرجع',
                    value: transaction.reference,
                  ),
                  _DetailRow(
                    label: 'معرف العملية',
                    value: transaction.id,
                    isLast: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return AppColors.success;
      case TransactionStatus.pending:
        return const Color(0xFFE6A23C);
      case TransactionStatus.failed:
        return AppColors.error;
    }
  }

  static String _statusText(TransactionStatus status) {
    switch (status) {
      case TransactionStatus.success:
        return 'ناجحة';
      case TransactionStatus.pending:
        return 'معلقة';
      case TransactionStatus.failed:
        return 'مرفوضة';
    }
  }
}

class _DetailsSection extends StatelessWidget {
  const _DetailsSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      decoration: BoxDecoration(
        color: const Color(0xFF12192B).withOpacity(0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
          bottom: BorderSide(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatAmount(double value) {
  final fixed = value.toStringAsFixed(2);
  final parts = fixed.split('.');
  final whole = parts[0];
  final decimal = parts[1];

  final reversed = whole.split('').reversed.toList();
  final buffer = StringBuffer();

  for (int i = 0; i < reversed.length; i++) {
    if (i > 0 && i % 3 == 0) {
      buffer.write(',');
    }
    buffer.write(reversed[i]);
  }

  final formattedWhole = buffer.toString().split('').reversed.join();
  return '$formattedWhole.$decimal';
}

String _formatDateTime(DateTime value) {
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final period = value.hour >= 12 ? 'PM' : 'AM';
  return '${value.year}/${value.month}/${value.day} • $hour:$minute $period';
}