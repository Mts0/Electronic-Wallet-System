import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/core/providers/core_providers.dart';
import 'package:y_wallet/features/app_lock/presentation/providers/app_lock_provider.dart';
import 'package:y_wallet/features/app_lock/presentation/widgets/pin_code_input.dart';

class ConfirmPinPage extends ConsumerStatefulWidget {
  const ConfirmPinPage({
    super.key,
    required this.firstPin,
  });

  final String firstPin;

  @override
  ConsumerState<ConfirmPinPage> createState() => _ConfirmPinPageState();
}

class _ConfirmPinPageState extends ConsumerState<ConfirmPinPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<PinCodeInputState> _pinKey = GlobalKey<PinCodeInputState>();

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  PinInputStatus _status = PinInputStatus.idle;
  int _successFilledCount = 0;
  bool _isHandling = false;
  String? _errorText;

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

  void _restartFromBeginning() {
    final resetId = DateTime.now().microsecondsSinceEpoch;
    context.go('${RouteNames.setupPin}?reset=$resetId');
  }

  Future<void> _handleCompleted(String pin) async {
    if (_isHandling) return;
    _isHandling = true;

    if (pin != widget.firstPin) {
      setState(() {
        _status = PinInputStatus.error;
        _errorText = 'رمز PIN غير متطابق';
      });

      await _shakeController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 320));

      _pinKey.currentState?.clearAll();

      if (!mounted) return;

      setState(() {
        _status = PinInputStatus.idle;
        _errorText = null;
      });

      _isHandling = false;
      return;
    }

    setState(() {
      _status = PinInputStatus.success;
      _successFilledCount = 0;
      _errorText = null;
    });

    for (int i = 1; i <= 4; i++) {
      await Future.delayed(const Duration(milliseconds: 110));
      if (!mounted) return;

      setState(() {
        _successFilledCount = i;
      });
    }

    final appLockService = ref.read(appLockServiceProvider);
    final biometricService = ref.read(biometricServiceProvider);
    final sessionStorage = ref.read(sessionStorageProvider);

    await appLockService.savePin(pin);

    if (!kIsWeb) {
      final biometricAvailable = await biometricService.isAvailable();

      if (biometricAvailable && mounted) {
        final enableBiometric = await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: const Color(0xFF192238),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              title: const Text(
                'تفعيل البصمة',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              content: const Text(
                'هل تريد استخدام البصمة لفتح التطبيق بشكل أسرع؟',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('ليس الآن'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('تفعيل'),
                ),
              ],
            );
          },
        );

        await sessionStorage.setBiometricEnabled(enableBiometric == true);
      } else {
        await sessionStorage.setBiometricEnabled(false);
      }
    } else {
      await sessionStorage.setBiometricEnabled(false);
    }

    ref.read(appUnlockedProvider.notifier).state = true;

    if (!mounted) return;
    context.go(RouteNames.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A1020),
              Color(0xFF10182B),
              Color(0xFF0C1323),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -90,
              left: -70,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6C7CFF).withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              right: -70,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.06),
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.06),
                          width: 1,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFF1A2238).withOpacity(0.96),
                            const Color(0xFF161D31).withOpacity(0.96),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.22),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconButton(
                            onPressed: _restartFromBeginning,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: const Text(
                              'تأكيد',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'تأكيد رمز PIN',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'أعد إدخال الرمز للتأكد من صحته قبل الحفظ',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                              height: 1.55,
                            ),
                          ),
                          const SizedBox(height: 24),
                          AnimatedBuilder(
                            animation: _shakeAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(_shakeAnimation.value, 0),
                                child: child,
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.inputFill.withOpacity(0.42),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                              child: Column(
                                children: [
                                  PinCodeInput(
                                    key: _pinKey,
                                    length: 4,
                                    status: _status,
                                    successFilledCount: _successFilledCount,
                                    onCompleted: _handleCompleted,
                                  ),
                                  const SizedBox(height: 6),
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    child: _errorText == null
                                        ? const Text(
                                      'سيتم الحفظ تلقائيًا بعد إدخال الخانات الأربع',
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
                          ),
                          const SizedBox(height: 18),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _restartFromBeginning,
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
                              child: const Text('إعادة إنشاء الرمز من البداية'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}