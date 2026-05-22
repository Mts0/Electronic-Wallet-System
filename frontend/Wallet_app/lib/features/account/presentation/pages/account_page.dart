import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/features/app_lock/presentation/providers/app_lock_provider.dart';
import 'package:y_wallet/features/auth/presentation/controllers/auth_controller.dart';
import 'package:y_wallet/features/kyc/domain/entities/kyc_entity.dart';
import 'package:y_wallet/features/kyc/presentation/controllers/kyc_controller.dart';

class AccountPage extends ConsumerWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final session = authState.value;
    final user = session?.user;
    final fullName = _readFullName(user);
    final phone = _readPhone(user);
    final kycState = ref.watch(currentUserKycProvider);

    Future<void> logout() async {
      ref.read(appUnlockedProvider.notifier).state = false;
      await ref.read(authControllerProvider.notifier).logout();

      if (!context.mounted) return;
      context.go(RouteNames.login);
    }

    Future<void> showLogoutDialog() async {
      await showDialog<void>(
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
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'تسجيل الخروج',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'هل تريد تسجيل الخروج من الحساب الحالي؟',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            foregroundColor: AppColors.textPrimary,
                          ),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            await logout();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error.withOpacity(0.16),
                            foregroundColor: AppColors.error,
                            elevation: 0,
                            minimumSize: const Size.fromHeight(50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'تأكيد',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
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

    void showComingSoon(String title) {
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
                    color: Colors.black.withOpacity(0.24),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.settings_outlined,
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
                  const Text(
                    'سيتم إكمال هذا القسم لاحقًا داخل إدارة الحساب',
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
              const Text(
                'الحساب',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              _AccountHeaderCard(
                fullName: fullName,
                phone: phone,
              ),
              const SizedBox(height: 18),
              _StatusOverviewRow(kycState: kycState),
              const SizedBox(height: 18),
              _AccountSection(
                title: 'التحقق من الهوية',
                children: [
                  _buildKycTile(context, kycState, phone),
                ],
              ),
              const SizedBox(height: 18),
              _AccountSection(
                title: 'الأمان',
                children: [
                  _AccountTile(
                    icon: Icons.password_rounded,
                    title: 'تغيير كلمة المرور',
                    subtitle: 'تحديث كلمة مرور الحساب',
                    onTap: () => context.push(RouteNames.changePassword),
                  ),
                  _AccountTile(
                    icon: Icons.pin_outlined,
                    title: 'تغيير رمز PIN',
                    subtitle: 'إعادة ضبط رمز فتح التطبيق',
                    onTap: () => context.push('${RouteNames.setupPin}?reset=change-pin'),
                  ),
                  _AccountTile(
                    icon: Icons.fingerprint_rounded,
                    title: 'إدارة البصمة',
                    subtitle: 'إعدادات الدخول بالبصمة',
                    onTap: () => showComingSoon('إدارة البصمة'),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _AccountSection(
                title: 'التفضيلات',
                children: [
                  _AccountTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'الإشعارات',
                    subtitle: 'تنبيهات التطبيق والعمليات',
                    onTap: () => context.push(RouteNames.notifications),
                  ),
                  _AccountTile(
                    icon: Icons.palette_outlined,
                    title: 'الثيم واللغة',
                    subtitle: 'المظهر واللغة للتطبيق',
                    onTap: () => context.push(RouteNames.appSettings),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _AccountSection(
                title: 'الدعم والمعلومات',
                children: [
                  _AccountTile(
                    icon: Icons.help_outline_rounded,
                    title: 'المساعدة والدعم',
                    subtitle: 'التواصل وطلب المساعدة',
                    onTap: () => showComingSoon('المساعدة والدعم'),
                  ),
                  _AccountTile(
                    icon: Icons.gpp_maybe_outlined,
                    title: 'شكوى احتيال',
                    subtitle: 'رفع بلاغ احتيال ومتابعة حالته',
                    onTap: () => context.push(RouteNames.fraudReports),
                  ),
                  _AccountTile(
                    icon: Icons.privacy_tip_outlined,
                    title: 'سياسة الخصوصية',
                    subtitle: 'معلومات الخصوصية والبيانات',
                    onTap: () => showComingSoon('سياسة الخصوصية'),
                  ),
                  _AccountTile(
                    icon: Icons.description_outlined,
                    title: 'الشروط والأحكام',
                    subtitle: 'بنود الاستخدام العامة',
                    onTap: () => showComingSoon('الشروط والأحكام'),
                  ),
                  _AccountTile(
                    icon: Icons.info_outline_rounded,
                    title: 'عن التطبيق',
                    subtitle: 'معلومات النسخة والدعم',
                    onTap: () => showComingSoon('عن التطبيق'),
                    isLast: true,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: showLogoutDialog,
                  icon: const Icon(Icons.logout_rounded),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error.withOpacity(0.14),
                    foregroundColor: AppColors.error,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  label: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKycTile(
    BuildContext context,
    AsyncValue<KycEntity> kycState,
    String phone,
  ) {
    return kycState.when(
      loading: () => _AccountTile(
        icon: Icons.verified_user_outlined,
        title: 'التحقق من الهوية',
        subtitle: 'جارٍ تحميل حالة KYC',
        onTap: _noop,
        isLast: true,
      ),
      error: (_, __) => _AccountTile(
        icon: Icons.error_outline_rounded,
        title: 'التحقق من الهوية',
        subtitle: 'تعذر تحميل الحالة، اضغط للمحاولة',
        onTap: () => context.push(RouteNames.kycIntro, extra: phone),
        isLast: true,
      ),
      data: (kyc) => _AccountTile(
        icon: _kycIcon(kyc.status),
        title: _kycTitle(kyc.status),
        subtitle: _kycSubtitle(kyc),
        onTap: () => _openKycFlow(context, kyc, phone),
        isLast: true,
      ),
    );
  }

  static void _noop() {}

  static IconData _kycIcon(KycStatus status) {
    switch (status) {
      case KycStatus.notStarted:
        return Icons.verified_user_outlined;
      case KycStatus.draft:
        return Icons.edit_note_rounded;
      case KycStatus.pending:
        return Icons.hourglass_top_rounded;
      case KycStatus.rejected:
        return Icons.error_outline_rounded;
      case KycStatus.approved:
        return Icons.check_circle_outline_rounded;
    }
  }

  static String _kycTitle(KycStatus status) {
    switch (status) {
      case KycStatus.notStarted:
        return 'إكمال KYC';
      case KycStatus.draft:
        return 'متابعة طلب KYC';
      case KycStatus.pending:
        return 'حالة KYC';
      case KycStatus.rejected:
        return 'إعادة تقديم KYC';
      case KycStatus.approved:
        return 'تم اعتماد KYC';
    }
  }

  static String _kycSubtitle(KycEntity kyc) {
    switch (kyc.status) {
      case KycStatus.notStarted:
        return 'بعض الخدمات المالية لن تعمل حتى تكمل التحقق';
      case KycStatus.draft:
        return 'هناك طلب غير مكتمل، أكمل البيانات والصور';
      case KycStatus.pending:
        return 'طلبك قيد المراجعة حاليًا';
      case KycStatus.rejected:
        final reason = (kyc.rejectionReason ?? '').trim();
        return reason.isEmpty ? 'تم رفض الطلب، يمكنك تحديثه وإعادة الإرسال' : 'تم رفض الطلب: $reason';
      case KycStatus.approved:
        return 'تم اعتماد هويتك ويمكنك استخدام الخدمات المقيدة';
    }
  }

  static void _openKycFlow(BuildContext context, KycEntity kyc, String phone) {
    switch (kyc.status) {
      case KycStatus.notStarted:
      case KycStatus.rejected:
        context.push(RouteNames.kycData, extra: phone.isNotEmpty ? phone : kyc.phoneNumber);
        break;
      case KycStatus.draft:
        if (!kyc.hasDataStepCompleted) {
          context.push(RouteNames.kycData, extra: phone.isNotEmpty ? phone : kyc.phoneNumber);
        } else if (!kyc.hasAllImages) {
          context.push(RouteNames.kycCapture, extra: phone.isNotEmpty ? phone : kyc.phoneNumber);
        } else {
          context.push(RouteNames.kycReview, extra: phone.isNotEmpty ? phone : kyc.phoneNumber);
        }
        break;
      case KycStatus.pending:
        context.push(RouteNames.kycSubmitted, extra: phone.isNotEmpty ? phone : kyc.phoneNumber);
        break;
      case KycStatus.approved:
        break;
    }
  }

  static String _readFullName(dynamic user) {
    try {
      final value = user?.fullName;
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    try {
      final value = user?.name;
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    return 'المستخدم';
  }

  static String _readPhone(dynamic user) {
    try {
      final value = user?.phoneNumber;
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    try {
      final value = user?.phone;
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    } catch (_) {}

    return 'رقم الهاتف غير متوفر';
  }
}

class _AccountHeaderCard extends StatelessWidget {
  const _AccountHeaderCard({
    required this.fullName,
    required this.phone,
  });

  final String fullName;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF12192B).withOpacity(0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withOpacity(0.24),
                  AppColors.primary.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.18),
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  phone,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: const [
                    _MiniBadge(
                      text: 'الحساب نشط',
                      color: AppColors.success,
                    ),
                    _MiniBadge(
                      text: 'قفل التطبيق مفعل',
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11.8,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusOverviewRow extends StatelessWidget {
  const _StatusOverviewRow({
    required this.kycState,
  });

  final AsyncValue<KycEntity> kycState;

  @override
  Widget build(BuildContext context) {
    String kycValue = 'جارٍ التحميل';
    Color kycAccent = const Color(0xFFE6A23C);

    kycState.whenData((kyc) {
      switch (kyc.status) {
        case KycStatus.notStarted:
          kycValue = 'غير مكتمل';
          kycAccent = const Color(0xFFE6A23C);
          break;
        case KycStatus.draft:
          kycValue = 'غير مكتمل';
          kycAccent = const Color(0xFFE6A23C);
          break;
        case KycStatus.pending:
          kycValue = 'قيد المراجعة';
          kycAccent = const Color(0xFFE6A23C);
          break;
        case KycStatus.rejected:
          kycValue = 'مرفوض';
          kycAccent = AppColors.error;
          break;
        case KycStatus.approved:
          kycValue = 'مكتمل';
          kycAccent = AppColors.success;
          break;
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: cardWidth,
              child: const _StatusCard(
                title: 'الحماية',
                value: 'مفعلة',
                accent: AppColors.success,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: const _StatusCard(
                title: 'الجلسة',
                value: 'نشطة الآن',
                accent: AppColors.primary,
              ),
            ),
            SizedBox(
              width: cardWidth,
              child: _StatusCard(
                title: 'KYC',
                value: kycValue,
                accent: kycAccent,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
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
              fontSize: 13.3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({
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

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isLast = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
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
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 22,
              ),
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
                      fontSize: 14.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.white.withOpacity(0.42),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}