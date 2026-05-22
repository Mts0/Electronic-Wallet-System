import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/features/app_lock/presentation/providers/app_lock_provider.dart';
import 'package:y_wallet/features/app_lock/presentation/widgets/pin_code_input.dart';

enum OperationAuthBottomSheetResult {
  completed,
  sessionExpired,
}

enum OperationVerificationResultKind {
  completed,
  inlineError,
  sessionExpired,
}

class OperationVerificationResult {
  final OperationVerificationResultKind kind;
  final String? message;

  const OperationVerificationResult._({
    required this.kind,
    this.message,
  });

  const OperationVerificationResult.completed()
      : this._(kind: OperationVerificationResultKind.completed);

  const OperationVerificationResult.inlineError(String message)
      : this._(
    kind: OperationVerificationResultKind.inlineError,
    message: message,
  );

  const OperationVerificationResult.sessionExpired([String? message])
      : this._(
    kind: OperationVerificationResultKind.sessionExpired,
    message: message,
  );
}

class OperationAuthBottomSheet extends ConsumerStatefulWidget {
  const OperationAuthBottomSheet({
    super.key,
    required this.title,
    required this.description,
    required this.onVerified,
  });

  final String title;
  final String description;
  final Future<OperationVerificationResult> Function() onVerified;

  @override
  ConsumerState<OperationAuthBottomSheet> createState() =>
      _OperationAuthBottomSheetState();
}

class _OperationAuthBottomSheetState
    extends ConsumerState<OperationAuthBottomSheet>
    with SingleTickerProviderStateMixin {
  final GlobalKey<PinCodeInputState> _pinKey = GlobalKey<PinCodeInputState>();

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  PinInputStatus _status = PinInputStatus.idle;
  int _successFilledCount = 0;
  String? _errorText;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );

    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -14), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -14, end: 14), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 14, end: -10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10, end: -6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6, end: 6), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6, end: 0), weight: 2),
    ]).animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _showPinError(String message) async {
    setState(() {
      _status = PinInputStatus.error;
      _errorText = message;
    });

    await _shakeController.forward(from: 0);
    await Future.delayed(const Duration(milliseconds: 280));

    _pinKey.currentState?.clearAll();

    if (!mounted) return;

    setState(() {
      _status = PinInputStatus.idle;
    });
  }

  Future<void> _handleVerificationResult(
      OperationVerificationResult result,
      ) async {
    switch (result.kind) {
      case OperationVerificationResultKind.completed:
        if (!mounted) return;
        Navigator.of(context).pop(OperationAuthBottomSheetResult.completed);
        break;
      case OperationVerificationResultKind.sessionExpired:
        if (!mounted) return;
        Navigator.of(context).pop(OperationAuthBottomSheetResult.sessionExpired);
        break;
      case OperationVerificationResultKind.inlineError:
        if (!mounted) return;
        setState(() {
          _status = PinInputStatus.error;
          _errorText = result.message ?? 'تعذر تنفيذ العملية';
        });
        break;
    }
  }

  Future<void> _completeLocalVerificationAndRun() async {
    final result = await widget.onVerified();

    if (!mounted) return;

    setState(() {
      _isProcessing = false;
    });

    await _handleVerificationResult(result);
  }

  Future<void> _handleCompleted(String pin) async {
    if (_isProcessing) return;
    _isProcessing = true;

    final appLockService = ref.read(appLockServiceProvider);
    final isValid = await appLockService.validatePin(pin);

    if (!isValid) {
      _isProcessing = false;
      await _showPinError('رمز PIN غير صحيح');
      return;
    }

    setState(() {
      _status = PinInputStatus.success;
      _successFilledCount = 0;
      _errorText = null;
    });

    for (int i = 1; i <= 4; i++) {
      await Future.delayed(const Duration(milliseconds: 95));
      if (!mounted) return;

      setState(() {
        _successFilledCount = i;
      });
    }

    await _completeLocalVerificationAndRun();
  }

  Future<void> _authenticateWithBiometric() async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
      _errorText = null;
      _status = PinInputStatus.idle;
    });

    final biometricService = ref.read(biometricServiceProvider);
    final success = await biometricService.authenticate();

    if (!mounted) return;

    if (!success) {
      setState(() {
        _isProcessing = false;
      });
      return;
    }

    await _completeLocalVerificationAndRun();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(28),
        ),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            18,
            12,
            18,
            18 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill.withOpacity(0.42),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.05),
                    ),
                  ),
                  child: Column(
                    children: [
                      AnimatedBuilder(
                        animation: _shakeAnimation,
                        builder: (context, child) {
                          return Transform.translate(
                            offset: Offset(_shakeAnimation.value, 0),
                            child: child,
                          );
                        },
                        child: PinCodeInput(
                          key: _pinKey,
                          length: 4,
                          status: _status,
                          successFilledCount: _successFilledCount,
                          onChanged: (_) {
                            if (_errorText != null) {
                              setState(() {
                                _errorText = null;
                                _status = PinInputStatus.idle;
                              });
                            }
                          },
                          onCompleted: _handleCompleted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 180),
                        child: _isProcessing
                            ? const Padding(
                          key: ValueKey('loading'),
                          padding: EdgeInsets.only(top: 4),
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                            ),
                          ),
                        )
                            : _errorText == null
                            ? const Text(
                          'سيتم التحقق تلقائيًا بعد إدخال الخانات الأربع',
                          key: ValueKey('hint'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12.5,
                          ),
                        )
                            : Text(
                          _errorText!,
                          key: const ValueKey('error'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.error,
                            fontSize: 12.8,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!kIsWeb) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isProcessing ? null : _authenticateWithBiometric,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        side: BorderSide(
                          color: Colors.white.withOpacity(0.08),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        foregroundColor: AppColors.textPrimary,
                      ),
                      icon: const Icon(Icons.fingerprint, size: 20),
                      label: const Text('استخدام البصمة'),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed:
                    _isProcessing ? null : () => Navigator.of(context).pop(),
                    child: const Text(
                      'إلغاء',
                      style: TextStyle(
                        color: AppColors.textSecondary,
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
}