import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/finance/entities/financial_operation_result.dart';
import 'package:y_wallet/core/finance/widgets/operation_result_page.dart';
import 'package:y_wallet/features/transactions/presentation/controllers/transaction_controller.dart';
import 'package:y_wallet/features/transfer/presentation/controllers/transfer_controller.dart';
import 'package:y_wallet/features/transfer/presentation/controllers/transfer_execution_controller.dart';
import 'package:y_wallet/features/wallet/presentation/controllers/wallet_controller.dart';

class TransferResultPage extends ConsumerStatefulWidget {
  const TransferResultPage({super.key});

  @override
  ConsumerState<TransferResultPage> createState() => _TransferResultPageState();
}

class _TransferResultPageState extends ConsumerState<TransferResultPage> {
  bool _didApplyChanges = false;
  bool _isLeavingPage = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _didApplyChanges) return;

      final form = ref.read(transferFormProvider);
      final executionState = ref.read(transferExecutionProvider);
      final result = executionState.result;

      if (!form.isReadyForConfirm || result == null) return;

      if (result.status == FinancialOperationStatus.success) {
        ref.read(walletControllerProvider.notifier).loadWallet();
      }

      ref.read(transactionControllerProvider.notifier).loadTransactions();
      _didApplyChanges = true;
    });
  }

  void _goToTransactions() {
    setState(() {
      _isLeavingPage = true;
    });

    context.go(RouteNames.transactions);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transferFormProvider.notifier).reset();
      ref.read(transferExecutionProvider.notifier).reset();
    });
  }

  void _goToDashboard() {
    setState(() {
      _isLeavingPage = true;
    });

    context.go(RouteNames.dashboard);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transferFormProvider.notifier).reset();
      ref.read(transferExecutionProvider.notifier).reset();
    });
  }

  void _goToTransferAgain() {
    setState(() {
      _isLeavingPage = true;
    });

    context.go(RouteNames.transfer);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(transferExecutionProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(transferFormProvider);
    final executionState = ref.watch(transferExecutionProvider);
    final result = executionState.result;

    if (!_isLeavingPage && (!form.isReadyForConfirm || result == null)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(RouteNames.transfer);
        }
      });

      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final safeResult = result ??
        const FinancialOperationResult(
          status: FinancialOperationStatus.failed,
          message: 'تعذر تحميل نتيجة العملية',
        );

    final amount = form.amount.trim().isEmpty ? '0.00' : form.amount.trim();
    final currency =
    form.fromCurrencyCode.trim().isEmpty ? '-' : form.fromCurrencyCode;

    return OperationResultPage(
      result: safeResult,
      amount: amount,
      currency: currency,
      onGoTransactions: _goToTransactions,
      onGoDashboard: _goToDashboard,
      onRetry: _goToTransferAgain,
      successTitle: 'تم تنفيذ التحويل بنجاح',
      pendingTitle: 'العملية قيد المعالجة',
      failedTitle: 'تعذر تنفيذ العملية',
      successDefaultMessage: (amount, currency) =>
      'تم تنفيذ تحويل بمبلغ $amount $currency بنجاح.',
      pendingDefaultMessage: (amount, currency) =>
      'تم استلام طلب التحويل بمبلغ $amount $currency وهو الآن قيد المعالجة.',
      failedDefaultMessage: (amount, currency) =>
      'لم يتم تنفيذ تحويل مبلغ $amount $currency.',
      retryLabel: 'العودة للتحويل',
    );
  }
}