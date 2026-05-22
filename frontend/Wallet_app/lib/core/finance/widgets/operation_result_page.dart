import 'package:flutter/material.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/finance/entities/financial_operation_result.dart';

class OperationResultPage extends StatelessWidget {
  const OperationResultPage({
    super.key,
    required this.result,
    required this.amount,
    required this.currency,
    required this.onGoTransactions,
    required this.onGoDashboard,
    required this.onRetry,
    required this.successTitle,
    required this.pendingTitle,
    required this.failedTitle,
    required this.successDefaultMessage,
    required this.pendingDefaultMessage,
    required this.failedDefaultMessage,
    this.retryLabel = 'إعادة المحاولة',
  });

  final FinancialOperationResult result;
  final String amount;
  final String currency;

  final VoidCallback onGoTransactions;
  final VoidCallback onGoDashboard;
  final VoidCallback onRetry;

  final String successTitle;
  final String pendingTitle;
  final String failedTitle;

  final String Function(String amount, String currency) successDefaultMessage;
  final String Function(String amount, String currency) pendingDefaultMessage;
  final String Function(String amount, String currency) failedDefaultMessage;

  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final presentation = _buildPresentation();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF090F1E),
              Color(0xFF0A1122),
              Color(0xFF0B1020),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              children: [
                const Spacer(),
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: presentation.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Icon(
                    presentation.icon,
                    color: presentation.accent,
                    size: 42,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  presentation.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  presentation.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: presentation.primaryAction ==
                        _OperationResultPrimaryAction.retry
                        ? onRetry
                        : onGoTransactions,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Text(
                      presentation.primaryLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: onGoDashboard,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      foregroundColor: AppColors.textPrimary,
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.08),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'العودة للرئيسية',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _OperationResultPresentation _buildPresentation() {
    final customMessage = result.message?.trim();
    final hasCustomMessage = customMessage != null && customMessage.isNotEmpty;

    switch (result.status) {
      case FinancialOperationStatus.success:
        return _OperationResultPresentation(
          accent: AppColors.success,
          icon: Icons.check_circle_outline_rounded,
          title: successTitle,
          primaryLabel: 'عرض العمليات',
          primaryAction: _OperationResultPrimaryAction.transactions,
          message: hasCustomMessage
              ? customMessage
              : successDefaultMessage(amount, currency),
        );

      case FinancialOperationStatus.pending:
        return _OperationResultPresentation(
          accent: const Color(0xFFE6A23C),
          icon: Icons.hourglass_top_rounded,
          title: pendingTitle,
          primaryLabel: 'عرض العمليات',
          primaryAction: _OperationResultPrimaryAction.transactions,
          message: hasCustomMessage
              ? customMessage
              : pendingDefaultMessage(amount, currency),
        );

      case FinancialOperationStatus.failed:
        return _OperationResultPresentation(
          accent: AppColors.error,
          icon: Icons.error_outline_rounded,
          title: failedTitle,
          primaryLabel: retryLabel,
          primaryAction: _OperationResultPrimaryAction.retry,
          message: hasCustomMessage
              ? customMessage
              : failedDefaultMessage(amount, currency),
        );
    }
  }
}

enum _OperationResultPrimaryAction {
  transactions,
  retry,
}

class _OperationResultPresentation {
  const _OperationResultPresentation({
    required this.accent,
    required this.icon,
    required this.title,
    required this.primaryLabel,
    required this.primaryAction,
    required this.message,
  });

  final Color accent;
  final IconData icon;
  final String title;
  final String primaryLabel;
  final _OperationResultPrimaryAction primaryAction;
  final String message;
}