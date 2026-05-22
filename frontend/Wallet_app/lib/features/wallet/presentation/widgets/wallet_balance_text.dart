import 'package:flutter/material.dart';
import 'package:y_wallet/app/theme/app_colors.dart';

class WalletBalanceText extends StatelessWidget {
  const WalletBalanceText({
    super.key,
    required this.balance,
    required this.currencyCode,
    required this.isVisible,
    this.compact = false,
  });

  final double balance;
  final String currencyCode;
  final bool isVisible;
  final bool compact;

  String _formatBalance(double value) {
    final fixed = value.toStringAsFixed(2);
    final parts = fixed.split('.');

    final whole = parts[0];
    final decimal = parts[1];

    final chars = whole.split('').reversed.toList();
    final buffer = StringBuffer();

    for (int i = 0; i < chars.length; i++) {
      if (i > 0 && i % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(chars[i]);
    }

    final formattedWhole = buffer.toString().split('').reversed.join();
    return '$formattedWhole.$decimal';
  }

  @override
  Widget build(BuildContext context) {
    final text = isVisible
        ? '${_formatBalance(balance)} $currencyCode'
        : '••••••••';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      child: Text(
        text,
        key: ValueKey(text),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: compact ? 18 : 26,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          height: 1.1,
        ),
      ),
    );
  }
}