import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/providers/core_providers.dart';
import 'package:y_wallet/features/auth/presentation/controllers/auth_controller.dart';

class ForgotPinVerifyPasswordPage extends ConsumerStatefulWidget {
  const ForgotPinVerifyPasswordPage({super.key});

  @override
  ConsumerState<ForgotPinVerifyPasswordPage> createState() =>
      _ForgotPinVerifyPasswordPageState();
}

class _ForgotPinVerifyPasswordPageState
    extends ConsumerState<ForgotPinVerifyPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isSubmitting = false;
  String? _passwordError;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'أدخل كلمة مرور الحساب';
    if (_passwordError != null) return _passwordError;
    return null;
  }

  Future<void> _submit() async {
    setState(() {
      _passwordError = null;
    });

    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;

    setState(() {
      _isSubmitting = true;
    });

    final sessionStorage = ref.read(sessionStorageProvider);
    final phone = await sessionStorage.getCurrentUserPhone();

    if (phone == null || phone.trim().isEmpty) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _passwordError = 'تعذر معرفة الحساب الحالي';
      });
      _formKey.currentState?.validate();
      return;
    }

    try {
      await ref.read(authRepositoryProvider).login(
            phoneNumber: phone.trim(),
            password: _passwordController.text.trim(),
          );

      await sessionStorage.clearPinCode();

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      context.go('${RouteNames.setupPin}?reset=forgot-pin');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _passwordError = e.toString().replaceFirst('Exception: ', '');
      });
      _formKey.currentState?.validate();
    }
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
                    'التحقق من كلمة المرور',
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
                    const Text(
                      'أدخل كلمة مرور الحساب للتحقق، ثم أعد تعيين رمز PIN فقط.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                      decoration: InputDecoration(
                        labelText: 'كلمة مرور الحساب',
                        hintText: 'أدخل كلمة المرور',
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
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
                            : const Text('متابعة'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () => context.go(RouteNames.forgotPinPhone),
                      child: const Text('نسيت كلمة المرور؟ المتابعة عبر الهاتف'),
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
