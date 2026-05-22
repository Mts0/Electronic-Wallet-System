import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:y_wallet/app/router/route_names.dart';
import 'package:y_wallet/app/theme/app_colors.dart';
import 'package:y_wallet/features/settings/presentation/providers/app_preferences_provider.dart';

class AppSettingsPage extends ConsumerWidget {
  const AppSettingsPage({super.key});

  void _goBackSafely(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(RouteNames.account);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF090F1E),
              Color(0xFF0A1122),
              Color(0xFF0B1020),
            ],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => _goBackSafely(context),
                    icon: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'إعدادات التطبيق',
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
              _SectionCard(
                title: 'المظهر',
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.dark,
                      groupValue: prefs.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(appPreferencesProvider.notifier).setThemeMode(value);
                        }
                      },
                      title: const Text('غامق'),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.light,
                      groupValue: prefs.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(appPreferencesProvider.notifier).setThemeMode(value);
                        }
                      },
                      title: const Text('فاتح'),
                    ),
                    RadioListTile<ThemeMode>(
                      value: ThemeMode.system,
                      groupValue: prefs.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(appPreferencesProvider.notifier).setThemeMode(value);
                        }
                      },
                      title: const Text('حسب النظام'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              _SectionCard(
                title: 'اللغة',
                child: Column(
                  children: [
                    RadioListTile<String>(
                      value: 'ar',
                      groupValue: prefs.locale.languageCode,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(appPreferencesProvider.notifier).setLocale(const Locale('ar'));
                        }
                      },
                      title: const Text('العربية'),
                    ),
                    RadioListTile<String>(
                      value: 'en',
                      groupValue: prefs.locale.languageCode,
                      onChanged: (value) {
                        if (value != null) {
                          ref.read(appPreferencesProvider.notifier).setLocale(const Locale('en'));
                        }
                      },
                      title: const Text('English'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF12192B).withOpacity(0.98),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: const Text(
                  'ملاحظة: التبديل يعمل الآن على مستوى إعدادات التطبيق. الشاشات الوظيفية الأساسية ستلتقط اللغة والثيم تدريجيًا حسب الربط الحالي.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF12192B).withOpacity(0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Theme(
            data: Theme.of(context).copyWith(
              listTileTheme: const ListTileThemeData(
                textColor: AppColors.textPrimary,
                iconColor: AppColors.primary,
              ),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
