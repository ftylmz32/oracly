/// OR-438 — Localization readiness layer (no UX change until wired).
library;

export 'app_strings_tr.dart';
export 'l10n_keys.dart';

import 'app_strings_tr.dart';

/// Resolves copy by language code — extend when English ships.
abstract final class OraclyL10n {
  OraclyL10n._();

  static String t(String key, {required String languageCode, String? fallback}) {
    return switch (languageCode.toLowerCase()) {
      'tr' || 'türkçe' || 'turkce' => AppStringsTr.resolve(key, fallback: fallback),
      _ => AppStringsTr.resolve(key, fallback: fallback),
    };
  }
}
