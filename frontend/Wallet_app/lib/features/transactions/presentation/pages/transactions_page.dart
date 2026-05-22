import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/widgets/custom_pull_to_refresh.dart';
import 'package:y_wallet/features/transactions/domain/entities/transaction_entity.dart';
import 'package:y_wallet/features/transactions/presentation/controllers/transaction_controller.dart';

class TransactionsPage extends ConsumerWidget {
  const TransactionsPage({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    await ref.read(transactionControllerProvider.notifier).loadTransactions();
    await Future.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsState = ref.watch(transactionControllerProvider);
    final selectedFilter = ref.watch(transactionFilterProvider);

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
          child: CustomPullToRefresh(
            onRefresh: () => _onRefresh(ref),
            child: transactionsState.when(
              loading: () => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                children: const [
                  _TransactionsLoadingView(),
                ],
              ),
              error: (error, _) => ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                children: [
                  _TransactionsErrorView(
                    onRetry: () {
                      ref
                          .read(transactionControllerProvider.notifier)
                          .loadTransactions();
                    },
                  ),
                ],
              ),
              data: (transactions) {
                final filtered = _filterTransactions(transactions, selectedFilter);
                final summary = _buildSummary(transactions);

                return ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
                  children: [
                    const _TransactionsHeader(),
                    const SizedBox(height: 10),
                    _SummaryRow(summary: summary),
                    const SizedBox(height: 16),
                    _TransactionsFilterBar(
                      selectedFilter: selectedFilter,
                      onChanged: (filter) {
                        ref.read(transactionFilterProvider.notifier).state =
                            filter;
                      },
                    ),
                    const SizedBox(height: 14),
                    if (filtered.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 120),
                        child: _EmptyTransactionsView(),
                      )
                    else
                      ...filtered.map(
                            (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TransactionTile(
                            item: item,
                            onTap: () {
                              context.push(
                                RouteNames.transactionDetails,
                                extra: item,
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  static List<TransactionEntity> _filterTransactions(
      List<TransactionEntity> items,
      TransactionFilter filter,
      ) {
    switch (filter) {
      case TransactionFilter.incoming:
        return items
            .where((item) => item.direction == TransactionDirection.incoming)
            .toList();
      case TransactionFilter.outgoing:
        return items
            .where((item) => item.direction == TransactionDirection.outgoing)
            .toList();
      case TransactionFilter.all:
        return items;
    }
  }

  static _TransactionsSummary _buildSummary(List<TransactionEntity> items) {
    double incoming = 0;
    double outgoing = 0;
    int pendingCount = 0;

    for (final item in items) {
      if (item.direction == TransactionDirection.incoming) {
        incoming += item.amount;
      } else {
        outgoing += item.amount;
      }

      if (item.status == TransactionStatus.pending) {
        pendingCount++;
      }
    }

    return _TransactionsSummary(
      totalIncoming: incoming,
      totalOutgoing: outgoing,
      pendingCount: pendingCount,
    );
  }
}

class _TransactionsHeader extends StatelessWidget {
  const _TransactionsHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: Text(
            'العمليات',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.summary,
  });

  final _TransactionsSummary summary;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'الوارد',
                value: _formatAmount(summary.totalIncoming),
                accent: AppColors.success,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'الصادر',
                value: _formatAmount(summary.totalOutgoing),
                accent: AppColors.primary,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _SummaryCard(
                title: 'المعلق',
                value: summary.pendingCount.toString(),
                accent: const Color(0xFFE6A23C),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.accent,
  });

  final String title;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF12192B).withOpacity(0.98),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 9,
            height: 9,
            decoration: BoxDecoration(
              color: accent,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: accent.withOpacity(0.24),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionsFilterBar extends StatelessWidget {
  const _TransactionsFilterBar({
    required this.selectedFilter,
    required this.onChanged,
  });

  final TransactionFilter selectedFilter;
  final ValueChanged<TransactionFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _FilterChipItem(
          label: 'الكل',
          isSelected: selectedFilter == TransactionFilter.all,
          onTap: () => onChanged(TransactionFilter.all),
        ),
        _FilterChipItem(
          label: 'وارد',
          isSelected: selectedFilter == TransactionFilter.incoming,
          onTap: () => onChanged(TransactionFilter.incoming),
        ),
        _FilterChipItem(
          label: 'صادر',
          isSelected: selectedFilter == TransactionFilter.outgoing,
          onTap: () => onChanged(TransactionFilter.outgoing),
        ),
      ],
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.16)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.34)
                : Colors.white.withOpacity(0.05),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
            isSelected ? AppColors.textPrimary : AppColors.textSecondary,
            fontSize: 12.8,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.item,
    required this.onTap,
  });

  final TransactionEntity item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(item.status);
    final directionColor = item.direction == TransactionDirection.incoming
        ? AppColors.success
        : AppColors.primary;
    final amountPrefix =
    item.direction == TransactionDirection.incoming ? '+' : '-';

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF12192B).withOpacity(0.98),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: directionColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                item.direction == TransactionDirection.incoming
                    ? Icons.call_received_rounded
                    : Icons.call_made_rounded,
                color: directionColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _statusText(item.status),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        _formatDateTime(item.createdAt),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 118),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$amountPrefix ${_formatAmount(item.amount)} ${item.currencyCode}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      color: directionColor,
                      fontSize: 13.6,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.reference,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

class _TransactionsLoadingView extends StatelessWidget {
  const _TransactionsLoadingView();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Align(
          alignment: Alignment.centerRight,
          child: Text(
            'العمليات',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: List.generate(
            3,
                (index) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: index == 2 ? 0 : 12),
                height: 86,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        ...List.generate(
          5,
              (_) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 92,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        ),
      ],
    );
  }
}

class _TransactionsErrorView extends StatelessWidget {
  const _TransactionsErrorView({
    required this.onRetry,
  });

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'تعذر تحميل العمليات',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'حدث خطأ أثناء تحميل البيانات',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: onRetry,
                child: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyTransactionsView extends StatelessWidget {
  const _EmptyTransactionsView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'لا توجد عمليات لعرضها',
        style: TextStyle(
          color: AppColors.textSecondary,
          fontSize: 14.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _TransactionsSummary {
  const _TransactionsSummary({
    required this.totalIncoming,
    required this.totalOutgoing,
    required this.pendingCount,
  });

  final double totalIncoming;
  final double totalOutgoing;
  final int pendingCount;
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