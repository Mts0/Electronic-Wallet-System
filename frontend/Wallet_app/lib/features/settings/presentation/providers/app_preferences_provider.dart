import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:y_wallet/core/providers/core_providers.dart';

class AppPreferencesState {
  final ThemeMode themeMode;
  final Locale locale;

  const AppPreferencesState({
    required this.themeMode,
    required this.locale,
  });

  AppPreferencesState copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return AppPreferencesState(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

class AppPreferencesController extends StateNotifier<AppPreferencesState> {
  AppPreferencesController(this._ref)
      : super(const AppPreferencesState(
          themeMode: ThemeMode.dark,
          locale: Locale('ar'),
        )) {
    _load();
  }

  final Ref _ref;
  static const _themeKey = 'app_theme_mode';
  static const _localeKey = 'app_locale';

  void _load() {
    final prefs = _ref.read(sharedPreferencesProvider);
    final rawTheme = prefs.getString(_themeKey) ?? 'dark';
    final rawLocale = prefs.getString(_localeKey) ?? 'ar';

    state = AppPreferencesState(
      themeMode: switch (rawTheme) {
        'light' => ThemeMode.light,
        'system' => ThemeMode.system,
        _ => ThemeMode.dark,
      },
      locale: Locale(rawLocale == 'en' ? 'en' : 'ar'),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setString(
      _themeKey,
      switch (mode) {
        ThemeMode.light => 'light',
        ThemeMode.system => 'system',
        ThemeMode.dark => 'dark',
      },
    );
  }

  Future<void> setLocale(Locale locale) async {
    state = state.copyWith(locale: locale);
    final prefs = _ref.read(sharedPreferencesProvider);
    await prefs.setString(_localeKey, locale.languageCode == 'en' ? 'en' : 'ar');
  }
}

final appPreferencesProvider =
    StateNotifierProvider<AppPreferencesController, AppPreferencesState>((ref) {
  return AppPreferencesController(ref);
});
