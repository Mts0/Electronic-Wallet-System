import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/utils/validators.dart';
import 'package:y_wallet/features/auth/presentation/controllers/auth_controller.dart';

class ResetPasswordPage extends ConsumerStatefulWidget {
  const ResetPasswordPage({
    super.key,
    required this.phoneNumber,
    required this.otpCode,
  });

  final String phoneNumber;
  final String otpCode;

  @override
  ConsumerState<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends ConsumerState<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _otpController;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _otpController = TextEditingController(text: widget.otpCode);
  }

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    try {
      final message = await ref.read(authRepositoryProvider).resetPassword(
            phoneNumber: widget.phoneNumber,
            otpCode: _otpController.text.trim(),
            newPassword: _passwordController.text.trim(),
          );

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await _showDialog('تم التحديث', message);
      if (!mounted) return;
      context.go(RouteNames.login);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await _showDialog('تعذر التحديث', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _showDialog(String title, String message) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF151C2E),
        title: Text(title, style: const TextStyle(color: AppColors.textPrimary)),
        content: Text(message, style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('حسنًا'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('تعيين كلمة مرور جديدة')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
              TextFormField(
                controller: _otpController,
                validator: AppValidators.validateOtp,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'رمز التحقق',
                  hintText: 'أدخل الرمز المرسل للهاتف',
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _passwordController,
                validator: AppValidators.validatePassword,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'كلمة المرور الجديدة',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _confirmPasswordController,
                validator: (value) => AppValidators.validateConfirmPassword(
                  value,
                  originalPassword: _passwordController.text,
                ),
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'تأكيد كلمة المرور',
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('حفظ كلمة المرور الجديدة'),
                ),
              ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
