import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/core/finance/widgets/operation_review_page.dart';
import 'package:y_wallet/core/widgets/operation_auth_bottom_sheet.dart';
import 'package:y_wallet/features/auth/presentation/controllers/auth_controller.dart';
import 'package:y_wallet/features/exchange/presentation/controllers/exchange_controller.dart';
import 'package:y_wallet/features/exchange/presentation/controllers/exchange_execution_controller.dart';
import 'package:y_wallet/features/exchange/presentation/controllers/exchange_quote_controller.dart';

class ExchangeConfirmPage extends ConsumerWidget {
  const ExchangeConfirmPage({super.key});

  void _goBackSafely(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(RouteNames.exchange);
    }
  }

  Future<void> _openAuthSheet(
    BuildContext context,
    WidgetRef ref,
    String amountText,
    String fromCurrencyCode,
    String toCurrencyCode,
  ) async {
    final outcome = await showModalBottomSheet<OperationAuthBottomSheetResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return OperationAuthBottomSheet(
          title: 'تأكيد المصارفة',
          description:
              'أدخل رمز PIN أو استخدم البصمة لتنفيذ مصارفة بمبلغ $amountText $fromCurrencyCode إلى $toCurrencyCode.',
          onVerified: () async {
            await ref.read(exchangeExecutionProvider.notifier).executeVerifiedExchange();

            final state = ref.read(exchangeExecutionProvider);

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
      context.go(RouteNames.exchangeResult);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final form = ref.watch(exchangeFormProvider);
    final quoteState = ref.watch(exchangeQuoteProvider);

    if (!form.isReadyForConfirm || quoteState.quote == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(RouteNames.exchange);
        }
      });

      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final exchange = form.toEntity();
    final quote = quoteState.quote!;
    final amountText = _formatAmount(exchange.fromAmount);
    final estimatedReceive = quote.estimateReceived(exchange.fromAmount);

    return OperationReviewPage(
      pageTitle: 'تأكيد المصارفة',
      icon: Icons.currency_exchange_rounded,
      amountText: amountText,
      currencyCode: exchange.fromCurrencyCode,
      rows: [
        OperationReviewRow(
          label: 'الحساب المصدر',
          value: '${exchange.fromAccountName} - ${exchange.fromCurrencyCode}',
        ),
        OperationReviewRow(
          label: 'رقم الحساب المصدر',
          value: exchange.fromAccountNumber,
        ),
        OperationReviewRow(
          label: 'الحساب الهدف',
          value: '${exchange.toAccountName} - ${exchange.toCurrencyCode}',
        ),
        OperationReviewRow(
          label: 'رقم الحساب الهدف',
          value: exchange.toAccountNumber,
        ),
        OperationReviewRow(
          label: 'المبلغ المراد صرفه',
          value: '$amountText ${exchange.fromCurrencyCode}',
        ),
        OperationReviewRow(
          label: 'سعر الصرف',
          value:
              '1 ${exchange.fromCurrencyCode} = ${quote.rateValue.toStringAsFixed(4)} ${exchange.toCurrencyCode}',
        ),
        OperationReviewRow(
          label: 'المبلغ المتوقع استلامه',
          value:
              '${_formatAmount(estimatedReceive)} ${exchange.toCurrencyCode}',
        ),
        OperationReviewRow(
          label: 'الملاحظة',
          value: exchange.notes.trim().isEmpty ? 'لا توجد ملاحظة' : exchange.notes,
        ),
      ],
      onEdit: () => _goBackSafely(context),
      onConfirm: () => _openAuthSheet(
        context,
        ref,
        amountText,
        exchange.fromCurrencyCode,
        exchange.toCurrencyCode,
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
