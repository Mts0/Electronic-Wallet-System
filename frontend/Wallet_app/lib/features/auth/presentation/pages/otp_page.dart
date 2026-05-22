import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/utils/validators.dart';
import 'package:y_wallet/features/auth/presentation/controllers/auth_controller.dart';

class OtpPage extends ConsumerStatefulWidget {
  const OtpPage({
    super.key,
    required this.phoneNumber,
    this.flow = 'register',
  });

  final String phoneNumber;
  final String flow;

  @override
  ConsumerState<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends ConsumerState<OtpPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isSubmitting = false;
  bool _isResending = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);

    try {
      if (widget.flow == 'password_reset') {
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        context.go(
          RouteNames.resetPassword,
          extra: {
            'phoneNumber': widget.phoneNumber,
            'otpCode': _otpController.text.trim(),
          },
        );
        return;
      }

      final message = await ref.read(authRepositoryProvider).verifyOtp(
            phoneNumber: widget.phoneNumber,
            otpCode: _otpController.text.trim(),
            verificationType: 'register',
          );

      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await _showDialog('تم التحقق', message);
      if (!mounted) return;
      context.go(RouteNames.login);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await _showDialog('تعذر التحقق', e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _resend() async {
    setState(() => _isResending = true);

    try {
      final String message;
      if (widget.flow == 'password_reset') {
        message = await ref.read(authRepositoryProvider).requestPasswordReset(
              phoneNumber: widget.phoneNumber,
            );
      } else {
        message = await ref.read(authRepositoryProvider).requestOtp(
              phoneNumber: widget.phoneNumber,
              verificationType: 'register',
            );
      }

      if (!mounted) return;
      setState(() => _isResending = false);
      await _showDialog('تم الإرسال', message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isResending = false);
      await _showDialog('تعذر الإرسال', e.toString().replaceFirst('Exception: ', ''));
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
    final isPasswordReset = widget.flow == 'password_reset';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('التحقق من الرمز')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isPasswordReset
                    ? 'أدخل رمز الاستعادة المرسل إلى ${widget.phoneNumber}'
                    : 'أدخل رمز التحقق المرسل إلى ${widget.phoneNumber}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: _otpController,
                validator: AppValidators.validateOtp,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'رمز OTP'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('متابعة'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isResending ? null : _resend,
                child: _isResending
                    ? const Text('جارٍ إعادة الإرسال...')
                    : const Text('إعادة إرسال الرمز'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
