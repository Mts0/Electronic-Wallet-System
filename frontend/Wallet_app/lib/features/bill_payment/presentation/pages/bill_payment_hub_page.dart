import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';

class BillPaymentHubPage extends StatelessWidget {
  const BillPaymentHubPage({super.key});

  void _goBackSafely(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(RouteNames.dashboard);
    }
  }

  Future<void> _showComingSoon(BuildContext context) async {
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

  @override
  Widget build(BuildContext context) {
    const communicationItems = [
      _BillMenuItem(
        title: 'شحن الهاتف',
        icon: Icons.phone_android_rounded,
        accent: Color(0xFF3B82F6),
        route: RouteNames.mobileTopup,
      ),
      _BillMenuItem(
        title: 'الباقات والبيانات',
        icon: Icons.wifi_tethering_rounded,
        accent: Color(0xFF10B981),
      ),
      _BillMenuItem(
        title: 'الهاتف الثابت والإنترنت المنزلي',
        icon: Icons.router_rounded,
        accent: Color(0xFFF59E0B),
      ),
    ];

    const serviceItems = [
      _BillMenuItem(
        title: 'فواتير الماء والكهرباء',
        icon: Icons.receipt_long_rounded,
        accent: Color(0xFF8B5CF6),
      ),
      _BillMenuItem(
        title: 'الرسوم التعليمية',
        icon: Icons.school_outlined,
        accent: Color(0xFF06B6D4),
      ),
      _BillMenuItem(
        title: 'خدمات أخرى',
        icon: Icons.apps_outage_rounded,
        accent: Color(0xFFE11D48),
      ),
    ];

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
                    onPressed: () => _goBackSafely(context),
                    icon: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'الشحن والسداد',
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
              const _SectionTitle(title: 'الاتصالات'),
              const SizedBox(height: 10),
              ...communicationItems.map(
                    (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BillMenuTile(
                    item: item,
                    onTap: () {
                      if (item.route != null) {
                        context.push(item.route!);
                        return;
                      }
                      _showComingSoon(context);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const _SectionTitle(title: 'الخدمات'),
              const SizedBox(height: 10),
              ...serviceItems.map(
                    (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _BillMenuTile(
                    item: item,
                    onTap: () => _showComingSoon(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _BillMenuItem {
  const _BillMenuItem({
    required this.title,
    required this.icon,
    required this.accent,
    this.route,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final String? route;
}

class _BillMenuTile extends StatelessWidget {
  const _BillMenuTile({
    required this.item,
    required this.onTap,
  });

  final _BillMenuItem item;
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
            color: Colors.white.withOpacity(0.05),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: item.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                item.icon,
                color: item.accent,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                item.title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14.3,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}