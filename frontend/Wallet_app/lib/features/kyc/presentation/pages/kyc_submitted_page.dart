import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';

class KycSubmittedPage extends StatelessWidget {
  const KycSubmittedPage({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              const Icon(Icons.hourglass_top_rounded, color: AppColors.success, size: 76),
              const SizedBox(height: 18),
              const Text(
                'تم إرسال طلب التحقق',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'الحالة الآن: قيد المراجعة. يمكنك متابعة استخدام التطبيق، لكن الخدمات الحساسة ستبقى مقيدة حتى الاعتماد.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.6),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go(RouteNames.dashboard),
                  child: const Text('العودة للرئيسية'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
