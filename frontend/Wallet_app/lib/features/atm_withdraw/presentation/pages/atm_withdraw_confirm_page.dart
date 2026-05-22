import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/core/finance/widgets/operation_review_page.dart';
import 'package:y_wallet/core/widgets/operation_auth_bottom_sheet.dart';
import 'package:y_wallet/features/atm_withdraw/presentation/controllers/atm_withdraw_controller.dart';
import 'package:y_wallet/features/atm_withdraw/presentation/controllers/atm_withdraw_execution_controller.dart';
import 'package:y_wallet/features/auth/presentation/controllers/auth_controller.dart';

class AtmWithdrawConfirmPage extends ConsumerWidget {
  const AtmWithdrawConfirmPage({super.key});

  void _goBackSafely(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(RouteNames.atmWithdraw);
    }
  }

  Future<void> _openAuthSheet(
    BuildContext context,
    WidgetRef ref,
    String amountText,
    String currency,
    String bankName,
  ) async {
    ref.read(atmWithdrawExecutionProvider.notifier).reset();

    final outcome = await showModalBottomSheet<OperationAuthBottomSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) {
        return OperationAuthBottomSheet(
          title: 'تأكيد تنفيذ العملية',
          description:
              'أكّد إنشاء طلب سحب بدون بطاقة بمبلغ $amountText $currency من خلال بنك $bankName.',
          onVerified: () async {
            await ref
                .read(atmWithdrawExecutionProvider.notifier)
                .executeVerifiedWithdraw();

            final state = ref.read(atmWithdrawExecutionProvider);

            if (state.requiresLogin) {
              return OperationVerificationResult.sessionExpired(
                state.localErrorMessage,
              );
            }

            if (state.receipt != null) {
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
      context.go(RouteNames.atmWithdrawResult);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(atmWithdrawFormProvider);

    if (!form.isReadyForConfirm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(RouteNames.atmWithdraw);
        }
      });

      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final amount = double.tryParse(form.amount.trim()) ?? 0;
    final amountText = _formatAmount(amount);

    return OperationReviewPage(
      pageTitle: 'تأكيد السحب بدون بطاقة',
      icon: Icons.local_atm_rounded,
      amountText: amountText,
      currencyCode: form.currencyCode,
      rows: [
        OperationReviewRow(
          label: 'الحساب المرسل',
          value: '${form.accountName} - ${form.currencyCode}',
        ),
        OperationReviewRow(
          label: 'رقم الحساب',
          value: form.accountNumber,
        ),
        OperationReviewRow(
          label: 'البنك',
          value: form.bankName,
        ),
        OperationReviewRow(
          label: 'المبلغ',
          value: '$amountText ${form.currencyCode}',
        ),
        OperationReviewRow(
          label: 'الملاحظة',
          value: form.note.trim().isEmpty ? 'لا توجد ملاحظة' : form.note,
        ),
      ],
      onEdit: () => _goBackSafely(context),
      onConfirm: () => _openAuthSheet(
        context,
        ref,
        amountText,
        form.currencyCode,
        form.bankName,
      ),
      confirmButtonText: 'تأكيد الطلب',
      reviewHint: 'راجع بيانات السحب قبل إنشاء الطلب',
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
