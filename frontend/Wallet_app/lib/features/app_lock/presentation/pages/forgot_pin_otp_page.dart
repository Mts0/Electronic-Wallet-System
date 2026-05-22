import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/utils/validators.dart';

class ForgotPinOtpPage extends StatefulWidget {
  const ForgotPinOtpPage({
    super.key,
    required this.phoneNumber,
  });

  final String phoneNumber;

  @override
  State<ForgotPinOtpPage> createState() => _ForgotPinOtpPageState();
}

class _ForgotPinOtpPageState extends State<ForgotPinOtpPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController otpController;

  String? _errorText;

  @override
  void initState() {
    super.initState();
    otpController = TextEditingController();
  }

  @override
  void dispose() {
    otpController.dispose();
    super.dispose();
  }

  void _continue() {
    setState(() {
      _errorText = null;
    });

    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final otpCode = otpController.text.trim();
    if (otpCode.isEmpty) {
      setState(() {
        _errorText = 'أدخل رمز OTP';
      });
      return;
    }

    // لا نتحقق من الرمز هنا عبر /auth/verify-otp لأن الباك اند يستهلك OTP عند التحقق.
    // التحقق الفعلي يتم داخل /auth/password/reset.
    context.push(
      RouteNames.forgotPinResetPassword,
      extra: {
        'phoneNumber': widget.phoneNumber,
        'otpCode': otpCode,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('رمز الاستعادة'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'أدخل رمز OTP المرسل إلى ${widget.phoneNumber}',
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: otpController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: AppValidators.validateOtp,
                decoration: const InputDecoration(
                  labelText: 'رمز OTP',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              if (_errorText != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_errorText!, style: const TextStyle(color: Colors.red)),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _continue,
                  child: const Text('متابعة'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
