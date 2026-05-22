import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/providers/core_providers.dart';
import 'package:y_wallet/features/kyc/domain/entities/kyc_entity.dart';
import 'package:y_wallet/features/kyc/presentation/controllers/kyc_controller.dart';
import 'package:y_wallet/features/wallet/presentation/controllers/wallet_controller.dart';
import 'package:y_wallet/features/transactions/presentation/controllers/transaction_controller.dart';

class KycReviewPage extends ConsumerStatefulWidget {
  const KycReviewPage({super.key, this.phoneNumber});

  final String? phoneNumber;

  @override
  ConsumerState<KycReviewPage> createState() => _KycReviewPageState();
}

class _KycReviewPageState extends ConsumerState<KycReviewPage> {
  bool _isSubmitting = false;
  String? _resolvedPhone;

  @override
  void initState() {
    super.initState();
    _resolvePhone();
  }

  Future<void> _resolvePhone() async {
    if (widget.phoneNumber != null && widget.phoneNumber!.trim().isNotEmpty) {
      setState(() => _resolvedPhone = widget.phoneNumber!.trim());
      return;
    }

    final phone = await ref.read(sessionStorageProvider).getCurrentUserPhone();
    if (!mounted) return;
    setState(() => _resolvedPhone = phone?.trim());
  }

  String _documentLabel(KycDocumentType? type) {
    switch (type) {
      case KycDocumentType.passport:
        return 'جواز سفر';
      case KycDocumentType.nationalId:
        return 'بطاقة شخصية';
      default:
        return '-';
    }
  }

  Future<void> _submit(String phone) async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(kycFlowProvider(phone).notifier).submitForReview();
      ref.invalidate(currentUserKycProvider);
      await ref.read(walletControllerProvider.notifier).loadWallet();
      await ref.read(transactionControllerProvider.notifier).loadTransactions();

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      context.go(RouteNames.kycSubmitted, extra: phone);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF151C2E),
          title: const Text('تعذر الإرسال', style: TextStyle(color: AppColors.textPrimary)),
          content: Text(e.toString().replaceFirst('Exception: ', ''), style: const TextStyle(color: AppColors.textSecondary)),
          actions: [TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('حسنًا'))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final phone = _resolvedPhone;
    if (phone == null) {
      return const Scaffold(backgroundColor: AppColors.background, body: Center(child: CircularProgressIndicator()));
    }
    final kycState = ref.watch(kycFlowProvider(phone));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('مراجعة طلب KYC')),
      body: kycState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(error.toString(), style: const TextStyle(color: AppColors.textPrimary))),
        data: (kyc) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Row(label: 'نوع الوثيقة', value: _documentLabel(kyc.documentType)),
            _Row(label: 'رقم الوثيقة', value: kyc.idNumber),
            _Row(label: 'الجنسية', value: kyc.nationality),
            _Row(label: 'الدولة', value: kyc.country.trim().isEmpty ? '-' : kyc.country),
            _Row(label: 'المدينة', value: kyc.city),
            _Row(label: 'الموقع', value: kyc.location),
            _Row(label: 'الشقة / المعلم', value: kyc.apartment.trim().isEmpty ? '-' : kyc.apartment),
            const SizedBox(height: 16),
            _StatusRow(title: 'صورة الأمام', isReady: kyc.idFrontImage?.isNotEmpty ?? false),
            _StatusRow(title: 'صورة الخلف', isReady: kyc.idBackImage?.isNotEmpty ?? false),
            _StatusRow(title: 'صورة السيلفي', isReady: kyc.selfieImage?.isNotEmpty ?? false),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: _isSubmitting ? null : () => _submit(phone),
              child: _isSubmitting
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2))
                  : const Text('إرسال للمراجعة'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
          Expanded(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(color: AppColors.textPrimary))),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.title, required this.isReady});
  final String title;
  final bool isReady;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(isReady ? Icons.check_circle_rounded : Icons.cancel_outlined, color: isReady ? AppColors.success : AppColors.error),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
