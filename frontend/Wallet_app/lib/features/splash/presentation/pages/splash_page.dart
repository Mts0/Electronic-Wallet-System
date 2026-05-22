import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/features/splash/domain/entities/app_start_route.dart';
import 'package:y_wallet/features/splash/presentation/providers/app_startup_provider.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _resolveRoute();
  }

  Future<void> _resolveRoute() async {
    if (_handled) return;
    _handled = true;

    final route = await ref.read(appStartupProvider.future);

    if (!mounted) return;

    switch (route) {
      case AppStartRoute.login:
        context.go(RouteNames.login);
        break;
      case AppStartRoute.home:
        context.go(RouteNames.dashboard);
        break;
      case AppStartRoute.appLock:
        context.go(RouteNames.appLock);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}