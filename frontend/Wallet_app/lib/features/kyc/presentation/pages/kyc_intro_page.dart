import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';

class KycIntroPage extends StatelessWidget {
  const KycIntroPage({super.key, this.phoneNumber});

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
              const Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 72),
              const SizedBox(height: 18),
              const Text(
                'أكمل التحقق من هويتك',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              const Text(
                'الخطوات الآن متوافقة مع الباك اند: بيانات KYC ثم رفع الصور ثم انتظار المراجعة.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.6),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.push(RouteNames.kycData, extra: phoneNumber),
                  child: const Text('ابدأ الآن'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => context.go(RouteNames.dashboard),
                  child: const Text('لاحقًا'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
