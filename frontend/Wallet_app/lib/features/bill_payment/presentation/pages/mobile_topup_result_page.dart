import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/finance/entities/financial_operation_result.dart';
import 'package:y_wallet/core/finance/widgets/operation_result_page.dart';
import 'package:y_wallet/features/bill_payment/presentation/controllers/mobile_topup_controller.dart';
import 'package:y_wallet/features/bill_payment/presentation/controllers/mobile_topup_execution_controller.dart';
import 'package:y_wallet/features/transactions/presentation/controllers/transaction_controller.dart';
import 'package:y_wallet/features/wallet/presentation/controllers/wallet_controller.dart';

class MobileTopupResultPage extends ConsumerStatefulWidget {
  const MobileTopupResultPage({super.key});

  @override
  ConsumerState<MobileTopupResultPage> createState() => _MobileTopupResultPageState();
}

class _MobileTopupResultPageState extends ConsumerState<MobileTopupResultPage> {
  bool _didRefresh = false;
  bool _isLeavingPage = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didRefresh) return;
    _didRefresh = true;
    Future.microtask(() async {
      await ref.read(walletControllerProvider.notifier).loadWallet();
      await ref.read(transactionControllerProvider.notifier).loadTransactions();
    });
  }

  void _goToTransactions() {
    setState(() => _isLeavingPage = true);
    context.go(RouteNames.transactions);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mobileTopupFormProvider.notifier).reset();
      ref.read(mobileTopupExecutionProvider.notifier).reset();
    });
  }

  void _goToDashboard() {
    setState(() => _isLeavingPage = true);
    context.go(RouteNames.dashboard);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mobileTopupFormProvider.notifier).reset();
      ref.read(mobileTopupExecutionProvider.notifier).reset();
    });
  }

  void _goToTopupAgain() {
    setState(() => _isLeavingPage = true);
    context.go(RouteNames.mobileTopup);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(mobileTopupExecutionProvider.notifier).reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(mobileTopupFormProvider);
    final executionState = ref.watch(mobileTopupExecutionProvider);
    final result = executionState.result;

    if (!_isLeavingPage && (!form.isReadyForConfirm || result == null)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          context.go(RouteNames.mobileTopup);
        }
      });

      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final safeResult = result ??
        const FinancialOperationResult(
          status: FinancialOperationStatus.failed,
          message: 'تعذر تحميل نتيجة العملية',
        );

    final amount = form.amount.trim().isEmpty ? '0.00' : form.amount.trim();
    final currency = form.fromCurrencyCode.trim().isEmpty ? '-' : form.fromCurrencyCode;

    return OperationResultPage(
      result: safeResult,
      amount: amount,
      currency: currency,
      onGoTransactions: _goToTransactions,
      onGoDashboard: _goToDashboard,
      onRetry: _goToTopupAgain,
      successTitle: 'تم تنفيذ الشحن بنجاح',
      pendingTitle: 'العملية قيد المعالجة',
      failedTitle: 'تعذر تنفيذ عملية الشحن',
      successDefaultMessage: (amount, currency) => 'تم شحن الهاتف بمبلغ $amount $currency بنجاح.',
      pendingDefaultMessage: (amount, currency) => 'تم استلام طلب شحن الهاتف بمبلغ $amount $currency وهو الآن قيد المعالجة.',
      failedDefaultMessage: (amount, currency) => 'لم يتم تنفيذ شحن الهاتف بمبلغ $amount $currency.',
      retryLabel: 'العودة للشحن',
    );
  }
}
