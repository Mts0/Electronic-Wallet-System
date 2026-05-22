import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/widgets/custom_pull_to_refresh.dart';
import 'package:y_wallet/features/auth/presentation/controllers/auth_controller.dart';
import 'package:y_wallet/features/kyc/domain/entities/kyc_entity.dart';
import 'package:y_wallet/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:y_wallet/features/kyc/presentation/providers/kyc_ui_provider.dart';
import 'package:y_wallet/features/kyc/presentation/widgets/kyc_status_banner.dart';
import 'package:y_wallet/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:y_wallet/features/wallet/presentation/widgets/wallet_carousel_section.dart';
import 'package:y_wallet/features/wallet/presentation/widgets/wallet_offers_banner.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  Future<void> _onRefresh(WidgetRef ref) async {
    await ref.read(walletControllerProvider.notifier).loadWallet();
    await ref.refresh(currentUserKycProvider.future);
    await Future.delayed(const Duration(milliseconds: 350));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final session = authState.value;
    final userName = session?.user.fullName ?? 'User';

    final kycState = ref.watch(currentUserKycProvider);
    final bannerDismissed = ref.watch(kycBannerDismissedProvider);

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
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
              children: [
                _HomeHeader(userName: userName),
                const SizedBox(height: 12),
                if (!bannerDismissed)
                  kycState.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (kyc) {
                      if (!_shouldShowKycBanner(kyc)) {
                        return const SizedBox.shrink();
                      }

                      final config = _buildBannerConfig(kyc);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: KycStatusBanner(
                          title: config.title,
                          subtitle: config.subtitle,
                          accent: config.accent,
                          icon: config.icon,
                          onTap: () => _openKycFlow(context, kyc),
                          onClose: () {
                            ref.read(kycBannerDismissedProvider.notifier).state =
                            true;
                          },
                        ),
                      );
                    },
                  ),
                const WalletCarouselSection(),
                const SizedBox(height: 14),
                const WalletOffersBanner(),
                const SizedBox(height: 18),
                const _ServicesGrid(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static bool _shouldShowKycBanner(KycEntity kyc) {
    return kyc.status != KycStatus.approved;
  }

  static _BannerConfig _buildBannerConfig(KycEntity kyc) {
    switch (kyc.status) {
      case KycStatus.notStarted:
        return const _BannerConfig(
          title: 'أكمل التحقق من هويتك',
          subtitle: 'بعض الخدمات مقيدة حتى تكمل KYC',
          accent: AppColors.primary,
          icon: Icons.verified_user_outlined,
        );
      case KycStatus.draft:
        return const _BannerConfig(
          title: 'لديك طلب تحقق غير مكتمل',
          subtitle: 'أكمل البيانات والصور لإرسال الطلب',
          accent: Color(0xFFE6A23C),
          icon: Icons.edit_note_rounded,
        );
      case KycStatus.pending:
        return const _BannerConfig(
          title: 'طلب التحقق قيد المراجعة',
          subtitle: 'ستتوفر الخدمات المقيدة بعد اعتماد الطلب',
          accent: Color(0xFFE6A23C),
          icon: Icons.hourglass_top_rounded,
        );
      case KycStatus.rejected:
        return const _BannerConfig(
          title: 'تم رفض طلب التحقق',
          subtitle: 'يمكنك تحديث البيانات وإعادة الإرسال',
          accent: AppColors.error,
          icon: Icons.error_outline_rounded,
        );
      case KycStatus.approved:
        return const _BannerConfig(
          title: '',
          subtitle: '',
          accent: AppColors.success,
          icon: Icons.check_circle_outline_rounded,
        );
    }
  }

  static void _openKycFlow(BuildContext context, KycEntity kyc) {
    switch (kyc.status) {
      case KycStatus.notStarted:
      case KycStatus.rejected:
        context.go(
          RouteNames.kycData,
          extra: kyc.phoneNumber,
        );
        break;
      case KycStatus.draft:
        if (!kyc.hasDataStepCompleted) {
          context.go(
            RouteNames.kycData,
            extra: kyc.phoneNumber,
          );
        } else if (!kyc.hasAllImages) {
          context.go(
            RouteNames.kycCapture,
            extra: kyc.phoneNumber,
          );
        } else {
          context.go(
            RouteNames.kycReview,
            extra: kyc.phoneNumber,
          );
        }
        break;
      case KycStatus.pending:
        context.go(
          RouteNames.kycSubmitted,
          extra: kyc.phoneNumber,
        );
        break;
      case KycStatus.approved:
        break;
    }
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.userName,
  });

  final String userName;

  String _shortName(String value) {
    final parts =
        value.trim().split(' ').where((e) => e.trim().isNotEmpty).toList();
    if (parts.isEmpty) return 'User';
    return parts.first;
  }

  @override
  Widget build(BuildContext context) {
    final name = _shortName(userName);

    return Row(
      children: [
        Expanded(
          child: Text(
            'مرحبًا، $name',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push(RouteNames.notifications),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
              ),
            ),
            child: const Icon(
              Icons.notifications_none_rounded,
              color: AppColors.textPrimary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _ServicesGrid extends ConsumerWidget {
  const _ServicesGrid();

  static const _services = [
    _ServiceItem(
      title: 'تحويلات مالية',
      icon: Icons.compare_arrows_rounded,
      accent: Color(0xFF3B82F6),
      requiresKyc: true,
    ),
    _ServiceItem(
      title: 'الشحن والسداد',
      icon: Icons.receipt_long_rounded,
      accent: Color(0xFF14B8A6),
      requiresKyc: true,
    ),
    _ServiceItem(
      title: 'سحب نقدي',
      icon: Icons.local_atm_rounded,
      accent: Color(0xFF8B5CF6),
      requiresKyc: true,
    ),
    _ServiceItem(
      title: 'شراء اونلاين',
      icon: Icons.shopping_bag_outlined,
      accent: Color(0xFF06B6D4),
      requiresKyc: true,
    ),
    _ServiceItem(
      title: 'محافظ وبنوك',
      icon: Icons.account_balance_wallet_outlined,
      accent: Color(0xFF10B981),
      requiresKyc: true,
    ),
    _ServiceItem(
      title: 'المصارفة',
      icon: Icons.currency_exchange_rounded,
      accent: Color(0xFF22C55E),
      requiresKyc: true,
    ),
    _ServiceItem(
      title: 'شبكة تحويل',
      icon: Icons.hub_outlined,
      accent: Color(0xFFF59E0B),
      requiresKyc: true,
    ),

  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kycState = ref.watch(currentUserKycProvider);

    return GridView.builder(
      itemCount: _services.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        mainAxisExtent: 132,
      ),
      itemBuilder: (context, index) {
        final item = _services[index];

        return InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            kycState.whenData((kyc) {
              final needsKyc =
                  item.requiresKyc && kyc.status != KycStatus.approved;

              if (needsKyc) {
                _showKycRestrictedDialog(
                  context: context,
                  kyc: kyc,
                );
                return;
              }

              if (item.title == 'تحويلات مالية') {
                context.push(RouteNames.transfer);
                return;
              }

              if (item.title == 'الشحن والسداد') {
                context.push(RouteNames.billPaymentHub);
                return;
              }

              if (item.title == 'سحب نقدي') {
                context.push(RouteNames.atmWithdraw);
                return;
              }

              if (item.title == 'المصارفة') {
                context.push(RouteNames.exchange);
                return;
              }



              _showComingSoon(context);
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF12192B).withOpacity(0.98),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ServiceIcon(
                  icon: item.icon,
                  accent: item.accent,
                ),
                const SizedBox(height: 14),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showComingSoon(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF151C2E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.access_time_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'الخدمة غير متاحة حاليًا',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'نعتذر منكم، سيتم إضافة هذه الخدمة قريبًا',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('حسنًا'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static void _showKycRestrictedDialog({
    required BuildContext context,
    required KycEntity kyc,
  }) {
    final title = _kycDialogTitle(kyc.status);
    final message = _kycDialogMessage(kyc);
    final actionText = _kycActionText(kyc.status);

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            decoration: BoxDecoration(
              color: const Color(0xFF151C2E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.06),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.08),
                          ),
                          foregroundColor: AppColors.textPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('إغلاق'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();

                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (context.mounted) {
                              context.go(RouteNames.account);
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(actionText),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static String _kycDialogTitle(KycStatus status) {
    switch (status) {
      case KycStatus.notStarted:
        return 'الخدمة مقيدة';
      case KycStatus.draft:
        return 'أكمل التحقق أولًا';
      case KycStatus.pending:
        return 'الطلب قيد المراجعة';
      case KycStatus.rejected:
        return 'تم رفض التحقق';
      case KycStatus.approved:
        return 'الخدمة متاحة';
    }
  }

  static String _kycDialogMessage(KycEntity kyc) {
    switch (kyc.status) {
      case KycStatus.notStarted:
        return 'هذه الخدمة حساسة وتتطلب إكمال التحقق من الهوية أولًا من الإعدادات.';
      case KycStatus.draft:
        return 'لديك طلب تحقق غير مكتمل. أكمل البيانات والصور من الإعدادات ثم أعد المحاولة.';
      case KycStatus.pending:
        return 'تم إرسال طلبك وهو الآن قيد المراجعة. ستتوفر الخدمة بعد الاعتماد.';
      case KycStatus.rejected:
        final reason = (kyc.rejectionReason ?? '').trim();
        if (reason.isNotEmpty) {
          return 'تم رفض الطلب. السبب: $reason';
        }
        return 'تم رفض طلب التحقق. يمكنك تحديث البيانات وإعادة الإرسال من الإعدادات.';
      case KycStatus.approved:
        return 'الخدمة متاحة.';
    }
  }

  static String _kycActionText(KycStatus status) {
    switch (status) {
      case KycStatus.notStarted:
        return 'إكمال';
      case KycStatus.draft:
        return 'إكمال';
      case KycStatus.pending:
        return 'عرض الحالة';
      case KycStatus.rejected:
        return 'إكمال';
      case KycStatus.approved:
        return 'متابعة';
    }
  }
}

class _ServiceIcon extends StatelessWidget {
  const _ServiceIcon({
    required this.icon,
    required this.accent,
  });

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withOpacity(0.20),
            accent.withOpacity(0.08),
          ],
        ),
        border: Border.all(
          color: accent.withOpacity(0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(
        icon,
        color: accent,
        size: 26,
      ),
    );
  }
}

class _ServiceItem {
  const _ServiceItem({
    required this.title,
    required this.icon,
    required this.accent,
    required this.requiresKyc,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final bool requiresKyc;
}

class _BannerConfig {
  const _BannerConfig({
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;
}