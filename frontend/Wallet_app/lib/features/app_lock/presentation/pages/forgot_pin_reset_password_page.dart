import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/providers/core_providers.dart';
import 'package:y_wallet/core/utils/validators.dart';
import 'package:y_wallet/features/auth/presentation/controllers/auth_controller.dart';

class ForgotPinResetPasswordPage extends ConsumerStatefulWidget {
  const ForgotPinResetPasswordPage({
    super.key,
    required this.phoneNumber,
    required this.otpCode,
  });

  final String phoneNumber;
  final String otpCode;

  @override
  ConsumerState<ForgotPinResetPasswordPage> createState() =>
      _ForgotPinResetPasswordPageState();
}

class _ForgotPinResetPasswordPageState
    extends ConsumerState<ForgotPinResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    return AppValidators.validatePassword(value);
  }

  String? _validateConfirmPassword(String? value) {
    return AppValidators.validateConfirmPassword(
      value,
      originalPassword: _passwordController.text,
    );
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    if (widget.phoneNumber.trim().isEmpty || widget.otpCode.trim().isEmpty) {
      await _showDialog('بيانات غير مكتملة', 'رقم الهاتف أو رمز OTP غير موجود. أعد بدء العملية من جديد.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final message = await ref.read(authRepositoryProvider).resetPassword(
            phoneNumber: widget.phoneNumber,
            otpCode: widget.otpCode,
            newPassword: _passwordController.text.trim(),
          );

      await ref.read(sessionStorageProvider).saveCurrentUserPhone(widget.phoneNumber);
      await ref.read(sessionStorageProvider).clearPinCode();

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      await _showDialog('تم التحديث', message);
      if (!mounted) return;
      context.go('${RouteNames.setupPin}?reset=forgot-pin');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      await _showDialog(
        'تعذر إتمام العملية',
        e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> _showDialog(String title, String message) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: const Color(0xFF151C2E),
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Text(
            message,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('حسنًا'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'تعيين كلمة مرور جديدة',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              decoration: BoxDecoration(
                color: const Color(0xFF12192B).withOpacity(0.98),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _PasswordField(
                      controller: _passwordController,
                      label: 'كلمة المرور الجديدة',
                      hint: 'أدخل كلمة المرور الجديدة',
                      obscureText: _obscurePassword,
                      onToggle: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 14),
                    _PasswordField(
                      controller: _confirmPasswordController,
                      label: 'تأكيد كلمة المرور',
                      hint: 'أعد إدخال كلمة المرور الجديدة',
                      obscureText: _obscureConfirmPassword,
                      onToggle: () {
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                      validator: _validateConfirmPassword,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2.2),
                              )
                            : const Text('حفظ كلمة المرور والمتابعة'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.obscureText,
    required this.onToggle,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final VoidCallback onToggle;
  final String? Function(String?) validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13.4,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: IconButton(
              onPressed: onToggle,
              icon: Icon(
                obscureText
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
