import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/features/wallet/presentation/controllers/wallet_controller.dart';

class WalletOffersBanner extends ConsumerWidget {
  const WalletOffersBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = ref.watch(walletCarouselIndexProvider);

    final offers = const [
      _OfferData(
        title: 'عرض خاص على الريال اليمني',
        subtitle: 'تحويلات أسرع ورسوم أقل لفترة محدودة',
        badge: 'YER',
        colors: [
          Color(0xFF4338CA),
          Color(0xFF2563EB),
        ],
        accent: Color(0xFFA78BFA),
      ),
      _OfferData(
        title: 'مزايا إضافية على الريال السعودي',
        subtitle: 'استخدم حسابك بمرونة أكبر وخدمات أوسع',
        badge: 'SAR',
        colors: [
          Color(0xFF0F9F96),
          Color(0xFF155E95),
        ],
        accent: Color(0xFF5EEAD4),
      ),
      _OfferData(
        title: 'خصومات على عمليات الدولار',
        subtitle: 'استفد من عروض خاصة على المدفوعات الرقمية',
        badge: 'USD',
        colors: [
          Color(0xFF1D4ED8),
          Color(0xFF1E3A8A),
        ],
        accent: Color(0xFF7DD3FC),
      ),
    ];

    final offer = offers[currentIndex % offers.length];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 550),
      switchInCurve: Curves.easeInOutCubic,
      switchOutCurve: Curves.easeInOutCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.06, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(currentIndex),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: offer.colors,
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.07),
          ),
          boxShadow: [
            BoxShadow(
              color: offer.colors.last.withOpacity(0.18),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                offer.badge,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    offer.title,
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
                    offer.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.82),
                      fontSize: 12.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: offer.accent.withOpacity(0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
              child: Text(
                'عرض',
                style: TextStyle(
                  color: offer.accent,
                  fontSize: 11.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferData {
  const _OfferData({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.colors,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final String badge;
  final List<Color> colors;
  final Color accent;
}