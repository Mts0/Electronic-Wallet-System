import 'package:flutter/material.dart';
import 'package:y_wallet/app/theme/app_colors.dart';

class WalletPageIndicator extends StatelessWidget {
  const WalletPageIndicator({
    super.key,
    required this.length,
    required this.currentIndex,
  });

  final int length;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        final isActive = index == currentIndex;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3.5),
          width: isActive ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withOpacity(0.95)
                : Colors.white.withOpacity(0.16),
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }),
    );
  }
}