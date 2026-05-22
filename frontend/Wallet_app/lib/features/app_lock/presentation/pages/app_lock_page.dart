import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/features/app_lock/presentation/providers/app_lock_provider.dart';
import 'package:y_wallet/features/app_lock/presentation/widgets/pin_code_input.dart';
import 'package:y_wallet/features/auth/presentation/controllers/auth_controller.dart';

class AppLockPage extends ConsumerStatefulWidget {
  const AppLockPage({super.key});

  @override
  ConsumerState<AppLockPage> createState() => _AppLockPageState();
}

class _AppLockPageState extends ConsumerState<AppLockPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey<PinCodeInputState> _pinKey = GlobalKey<PinCodeInputState>();

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  PinInputStatus _status = PinInputStatus.idle;
  int _successFilledCount = 0;
  String? _errorText;
  bool _isHandling = false;
  bool _triedBiometric = false;

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

    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _tryBiometric();
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometric() async {
    if (_triedBiometric) return;
    _triedBiometric = true;

    final biometricService = ref.read(biometricServiceProvider);
    final isAvailable = await biometricService.isAvailable();
    if (!isAvailable) return;

    final success = await biometricService.authenticate();
    if (!mounted || !success) return;

    ref.read(appUnlockedProvider.notifier).state = true;
    context.go(RouteNames.dashboard);
  }

  Future<void> _handleCompleted(String pin) async {
    if (_isHandling) return;
    _isHandling = true;

    final appLockService = ref.read(appLockServiceProvider);
    final isValid = await appLockService.validatePin(pin);

    if (!isValid) {
      setState(() {
        _status = PinInputStatus.error;
        _errorText = 'رمز PIN غير صحيح';
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

    ref.read(appUnlockedProvider.notifier).state = true;

    await Future.delayed(const Duration(milliseconds: 180));
    if (!mounted) return;

    context.go(RouteNames.dashboard);
  }

  Future<void> _unlockWithBiometric() async {
    final biometricService = ref.read(biometricServiceProvider);
    final success = await biometricService.authenticate();

    if (!mounted || !success) return;

    ref.read(appUnlockedProvider.notifier).state = true;
    context.go(RouteNames.dashboard);
  }

  Future<void> _goToLogin() async {
    ref.read(appUnlockedProvider.notifier).state = false;
    await ref.read(authControllerProvider.notifier).logout();

    if (!mounted) return;
    context.go(RouteNames.login);
  }

  void _forgotPin() {
    context.push(RouteNames.forgotPinVerifyPassword);
  }

  @override
  Widget build(BuildContext context) {
    final showBiometricButton = !kIsWeb;

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
              right: -70,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -70,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF6C7CFF).withOpacity(0.05),
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
                            onPressed: () => _goToLogin(),
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
                              'أمان',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'فتح التطبيق',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'أدخل رمز PIN لمتابعة الوصول إلى حسابك',
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
                          ),
                          if (showBiometricButton) ...[
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _unlockWithBiometric,
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
                          const SizedBox(height: 14),
                          Center(
                            child: TextButton(
                              onPressed: _forgotPin,
                              child: const Text(
                                'نسيت رمز PIN؟',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 13.5,
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
              ),
            ),
          ],
        ),
      ),
    );
  }
}