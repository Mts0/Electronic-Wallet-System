import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/providers/core_providers.dart';
import 'package:y_wallet/core/widgets/custom_pull_to_refresh.dart';
import 'package:y_wallet/features/transactions/domain/entities/transaction_entity.dart';
import 'package:y_wallet/features/transactions/presentation/controllers/transaction_controller.dart';

final notificationsProvider = FutureProvider<List<AppNotificationItem>>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/support/notifications/me', queryParameters: {'limit': 50});
    final data = response.data;
    if (data is List) {
      return data
          .whereType<Object>()
          .map((item) => AppNotificationItem.fromJson(item))
          .toList();
    }
    return const <AppNotificationItem>[];
  } on DioException {
    return const <AppNotificationItem>[];
  }
});

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  final int id;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;

  factory AppNotificationItem.fromJson(Object json) {
    final map = json is Map<String, dynamic>
        ? json
        : json is Map
            ? Map<String, dynamic>.from(json)
            : <String, dynamic>{};
    return AppNotificationItem(
      id: ((map['notification_id'] ?? 0) as num?)?.toInt() ?? 0,
      title: (map['title'] ?? 'إشعار').toString(),
      message: (map['message'] ?? '').toString(),
      isRead: map['is_read'] == true,
      createdAt: DateTime.tryParse((map['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    await ref.read(transactionControllerProvider.notifier).loadTransactions();
    await ref.refresh(notificationsProvider.future);
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _markAsRead(WidgetRef ref, int id) async {
    if (id <= 0) return;
    final dio = ref.read(dioProvider);
    try {
      await dio.post('/support/notifications/me/$id/read');
      ref.invalidate(notificationsProvider);
    } on DioException {
      // تجاهل الفشل هنا حتى لا نكسر الواجهة.
    }
  }

  void _goBackSafely(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(RouteNames.dashboard);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsState = ref.watch(notificationsProvider);
    final transactionsState = ref.watch(transactionControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('الإشعارات والنشاط'),
        leading: IconButton(
          onPressed: () => _goBackSafely(context),
          icon: const Icon(Icons.arrow_forward_ios_rounded),
        ),
      ),
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
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
              children: [
                const _SectionTitle('الإشعارات العامة'),
                const SizedBox(height: 10),
                notificationsState.when(
                  loading: () => const _InfoCard(
                    icon: Icons.notifications_none_rounded,
                    title: 'جارٍ تحميل الإشعارات',
                    subtitle: 'يرجى الانتظار قليلًا',
                  ),
                  error: (_, __) => const _InfoCard(
                    icon: Icons.notifications_off_outlined,
                    title: 'تعذر تحميل الإشعارات',
                    subtitle: 'سيظل سجل النشاط متاحًا أدناه',
                  ),
                  data: (items) {
                    if (items.isEmpty) {
                      return const _InfoCard(
                        icon: Icons.notifications_none_rounded,
                        title: 'لا توجد إشعارات حاليًا',
                        subtitle: 'سيتم عرض التنبيهات العامة هنا عند توفرها',
                      );
                    }
                    return Column(
                      children: items
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _NotificationTile(
                                item: item,
                                onTap: () => _markAsRead(ref, item.id),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 10),
                const _SectionTitle('النشاط الأخير'),
                const SizedBox(height: 10),
                transactionsState.when(
                  loading: () => const _InfoCard(
                    icon: Icons.receipt_long_rounded,
                    title: 'جارٍ تحميل النشاط',
                    subtitle: 'يتم تجهيز آخر العمليات',
                  ),
                  error: (_, __) => const _InfoCard(
                    icon: Icons.error_outline_rounded,
                    title: 'تعذر تحميل النشاط',
                    subtitle: 'تحقق من الاتصال ثم أعد المحاولة بالسحب للأسفل',
                  ),
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const _InfoCard(
                        icon: Icons.receipt_long_outlined,
                        title: 'لا يوجد نشاط بعد',
                        subtitle: 'ستظهر التحويلات والشحن والمصارفة هنا تلقائيًا',
                      );
                    }

                    final sorted = [...transactions]
                      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                    return Column(
                      children: sorted
                          .take(30)
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ActivityTile(
                                item: item,
                                onTap: () => context.push(
                                  RouteNames.transactionDetails,
                                  extra: item,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF12192B).withOpacity(0.98),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12.8,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.item,
    required this.onTap,
  });

  final AppNotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF12192B).withOpacity(0.98),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: item.isRead
                ? Colors.white.withOpacity(0.05)
                : AppColors.primary.withOpacity(0.35),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (item.isRead ? AppColors.textSecondary : AppColors.primary).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                item.isRead ? Icons.mark_email_read_outlined : Icons.notifications_active_outlined,
                color: item.isRead ? AppColors.textSecondary : AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14.2,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatRelativeTime(item.createdAt),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11.8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.message,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.8,
                      height: 1.45,
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
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.item,
    required this.onTap,
  });

  final TransactionEntity item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final amountColor = item.direction == TransactionDirection.incoming
        ? AppColors.success
        : AppColors.primary;
    final prefix = item.direction == TransactionDirection.incoming ? '+' : '-';

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        decoration: BoxDecoration(
          color: const Color(0xFF12192B).withOpacity(0.98),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: amountColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                item.direction == TransactionDirection.incoming
                    ? Icons.call_received_rounded
                    : Icons.call_made_rounded,
                color: amountColor,
                size: 24,
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
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.6,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$prefix ${item.amount.toStringAsFixed(2)} ${item.currencyCode}',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: amountColor,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRelativeTime(item.createdAt),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.8,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

String _formatRelativeTime(DateTime value) {
  final now = DateTime.now();
  final diff = now.difference(value);
  if (diff.inMinutes < 1) return 'الآن';
  if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
  if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
  if (diff.inDays < 7) return 'منذ ${diff.inDays} ي';
  return '${value.year}/${value.month.toString().padLeft(2, '0')}/${value.day.toString().padLeft(2, '0')}';
}
