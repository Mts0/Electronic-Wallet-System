import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/core/finance/widgets/operation_review_page.dart';
import 'package:y_wallet/core/widgets/operation_auth_bottom_sheet.dart';
import 'package:y_wallet/features/auth/presentation/controllers/auth_controller.dart';
import 'package:y_wallet/features/bill_payment/presentation/controllers/mobile_topup_controller.dart';
import 'package:y_wallet/features/bill_payment/presentation/controllers/mobile_topup_execution_controller.dart';

class MobileTopupConfirmPage extends ConsumerWidget {
  const MobileTopupConfirmPage({super.key});

  void _goBackSafely(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(RouteNames.mobileTopup);
    }
  }

  Future<void> _openAuthSheet(
      BuildContext context,
      WidgetRef ref,
      String amountText,
      String currency,
      String phoneNumber,
      ) async {
    ref.read(mobileTopupExecutionProvider.notifier).reset();

    final outcome = await showModalBottomSheet<OperationAuthBottomSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) {
        return OperationAuthBottomSheet(
          title: 'تأكيد تنفيذ العملية',
          description:
          'أكّد شحن الهاتف بمبلغ $amountText $currency للرقم $phoneNumber',
          onVerified: () async {
            await ref
                .read(mobileTopupExecutionProvider.notifier)
                .executeVerifiedTopup();

            final state = ref.read(mobileTopupExecutionProvider);

            if (state.requiresLogin) {
              return OperationVerificationResult.sessionExpired(
                state.localErrorMessage,
              );
            }

            if (state.result != null) {
              return const OperationVerificationResult.completed();
            }

            return OperationVerificationResult.inlineError(
              state.localErrorMessage ?? 'تعذر تنفيذ العملية',
            );
          },
        );
      },
    );

    if (!context.mounted) return;

    if (outcome == OperationAuthBottomSheetResult.sessionExpired) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) {
        context.go(RouteNames.login);
      }
      return;
    }

    if (outcome == OperationAuthBottomSheetResult.completed) {
      context.go(RouteNames.mobileTopupResult);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(mobileTopupFormProvider);

    if (!form.isReadyForConfirm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(RouteNames.mobileTopup);
        }
      });

      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final topup = form.toEntity();
    final amountText = _formatAmount(topup.amount);

    return OperationReviewPage(
      pageTitle: 'مراجعة شحن الهاتف',
      icon: Icons.phone_android_rounded,
      amountText: amountText,
      currencyCode: topup.fromCurrencyCode,
      rows: [
        OperationReviewRow(
          label: 'الحساب المرسل',
          value: '${topup.fromAccountName} - ${topup.fromCurrencyCode}',
        ),
        OperationReviewRow(
          label: 'رقم الحساب',
          value: topup.fromAccountNumber,
        ),
        OperationReviewRow(
          label: 'رقم الهاتف',
          value: topup.phoneNumber,
        ),
        OperationReviewRow(
          label: 'الشبكة',
          value: topup.operatorName,
        ),
        OperationReviewRow(
          label: 'المبلغ',
          value: '$amountText ${topup.fromCurrencyCode}',
        ),
        OperationReviewRow(
          label: 'الملاحظة',
          value: topup.notes.trim().isEmpty ? 'لا توجد ملاحظة' : topup.notes,
        ),
      ],
      onEdit: () => _goBackSafely(context),
      onConfirm: () => _openAuthSheet(
        context,
        ref,
        amountText,
        topup.fromCurrencyCode,
        topup.phoneNumber,
      ),
    );
  }

  static String _formatAmount(double value) {
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
}