import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/providers/core_providers.dart';
import 'package:y_wallet/core/utils/validators.dart';
import 'package:y_wallet/features/auth/presentation/controllers/auth_controller.dart';

class ForgotPinPhonePage extends ConsumerStatefulWidget {
  const ForgotPinPhonePage({super.key});

  @override
  ConsumerState<ForgotPinPhonePage> createState() => _ForgotPinPhonePageState();
}

class _ForgotPinPhonePageState extends ConsumerState<ForgotPinPhonePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController phoneController;

  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    phoneController = TextEditingController();
  }

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    setState(() {
      _errorText = null;
    });

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    setState(() {
      _isSubmitting = true;
    });

    final sessionStorage = ref.read(sessionStorageProvider);
    final currentPhone = await sessionStorage.getCurrentUserPhone();
    final phone = phoneController.text.trim();

    if (currentPhone == null || currentPhone.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = 'تعذر معرفة الحساب الحالي';
      });
      return;
    }

    if (phone != currentPhone.trim()) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = 'أدخل رقم الحساب الحالي';
      });
      return;
    }

    try {
      final message = await ref.read(authRepositoryProvider).requestPasswordReset(
            phoneNumber: phone,
          );

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      await _showDialog('تم الإرسال', message);
      if (!mounted) return;
      context.push(RouteNames.forgotPinOtp, extra: phone);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('استعادة كلمة المرور للحساب'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'أدخل رقم الهاتف المرتبط بالحساب الحالي لإرسال رمز استعادة كلمة المرور.',
                style: TextStyle(color: AppColors.textSecondary, height: 1.5),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: AppValidators.validatePhone,
                decoration: const InputDecoration(
                  labelText: 'رقم الهاتف',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorText!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _sendOtp,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('إرسال رمز الاستعادة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
