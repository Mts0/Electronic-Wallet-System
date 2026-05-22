import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/core/finance/widgets/operation_review_page.dart';
import 'package:y_wallet/core/widgets/operation_auth_bottom_sheet.dart';
import 'package:y_wallet/features/auth/presentation/controllers/auth_controller.dart';
import 'package:y_wallet/features/transfer/presentation/controllers/transfer_controller.dart';
import 'package:y_wallet/features/transfer/presentation/controllers/transfer_execution_controller.dart';

class TransferConfirmPage extends ConsumerWidget {
  const TransferConfirmPage({super.key});

  void _goBackSafely(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(RouteNames.transfer);
    }
  }

  Future<void> _openAuthSheet(
      BuildContext context,
      WidgetRef ref,
      String amountText,
      String currency,
      String walletNumber,
      ) async {
    ref.read(transferExecutionProvider.notifier).reset();

    final outcome = await showModalBottomSheet<OperationAuthBottomSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (_) {
        return OperationAuthBottomSheet(
          title: 'تأكيد تنفيذ العملية',
          description:
          'أكّد التحويل بمبلغ $amountText $currency إلى $walletNumber',
          onVerified: () async {
            await ref
                .read(transferExecutionProvider.notifier)
                .executeVerifiedTransfer();

            final state = ref.read(transferExecutionProvider);

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
      context.go(RouteNames.transferResult);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(transferFormProvider);

    if (!form.isReadyForConfirm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(RouteNames.transfer);
        }
      });

      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final transfer = form.toEntity();
    final amountText = _formatAmount(transfer.amount);

    return OperationReviewPage(
      pageTitle: 'تأكيد التحويل',
      icon: Icons.compare_arrows_rounded,
      amountText: amountText,
      currencyCode: transfer.fromCurrencyCode,
      rows: [
        OperationReviewRow(
          label: 'الحساب المرسل',
          value: '${transfer.fromAccountName} - ${transfer.fromCurrencyCode}',
        ),
        OperationReviewRow(
          label: 'رقم الحساب',
          value: transfer.fromAccountNumber,
        ),
        OperationReviewRow(
          label: 'رقم محفظة المستلم',
          value: transfer.toWalletNumber,
        ),
        OperationReviewRow(
          label: 'العملة',
          value: transfer.fromCurrencyCode,
        ),
        OperationReviewRow(
          label: 'المبلغ',
          value: '$amountText ${transfer.fromCurrencyCode}',
        ),
        OperationReviewRow(
          label: 'الملاحظة',
          value:
          transfer.notes.trim().isEmpty ? 'لا توجد ملاحظة' : transfer.notes,
        ),
      ],
      onEdit: () => _goBackSafely(context),
      onConfirm: () => _openAuthSheet(
        context,
        ref,
        amountText,
        transfer.fromCurrencyCode,
        transfer.toWalletNumber,
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