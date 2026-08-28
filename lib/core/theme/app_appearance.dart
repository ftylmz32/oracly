/// Runtime appearance — Dark / Light / System → [ThemeMode].
library;

import 'package:flutter/material.dart';

enum AppAppearanceMode { dark, light, system }

extension AppAppearanceModeX on AppAppearanceMode {
  ThemeMode get themeMode => switch (this) {
        AppAppearanceMode.dark => ThemeMode.dark,
        AppAppearanceMode.light => ThemeMode.light,
        AppAppearanceMode.system => ThemeMode.system,
      };

  static AppAppearanceMode fromStorage(
    String? raw, {
    required bool legacyDark,
  }) {
    switch (raw) {
      case 'light':
        return AppAppearanceMode.light;
      case 'system':
        return AppAppearanceMode.system;
      case 'dark':
        return AppAppearanceMode.dark;
      default:
        return legacyDark ? AppAppearanceMode.dark : AppAppearanceMode.light;
    }
  }
}
