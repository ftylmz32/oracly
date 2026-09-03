/// Runtime appearance — Dark / Light / System → [ThemeMode].
///
/// Light ThemeData remains in the architecture for a post-v1 project.
/// Production v1 is Dark-only: user cannot select Light/System.
library;

import 'package:flutter/material.dart';

enum AppAppearanceMode { dark, light, system }

extension AppAppearanceModeX on AppAppearanceMode {
  /// When false, production forces Dark regardless of stored preference.
  static const bool lightModeUserSelectable = false;

  ThemeMode get themeMode => switch (this) {
        AppAppearanceMode.dark => ThemeMode.dark,
        AppAppearanceMode.light => ThemeMode.light,
        AppAppearanceMode.system => ThemeMode.system,
      };

  /// Canonical production [ThemeMode] — single source of truth for v1.
  static ThemeMode get productionThemeMode => ThemeMode.dark;

  /// Coerce stored/user choice for release. Architecture keeps light/system.
  static AppAppearanceMode coerceForProduction(AppAppearanceMode mode) {
    if (lightModeUserSelectable) return mode;
    return AppAppearanceMode.dark;
  }

  static AppAppearanceMode fromStorage(
    String? raw, {
    required bool legacyDark,
  }) {
    final parsed = switch (raw) {
      'light' => AppAppearanceMode.light,
      'system' => AppAppearanceMode.system,
      'dark' => AppAppearanceMode.dark,
      _ => legacyDark ? AppAppearanceMode.dark : AppAppearanceMode.light,
    };
    return coerceForProduction(parsed);
  }
}
