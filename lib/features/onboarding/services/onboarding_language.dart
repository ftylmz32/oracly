/// Onboarding language resolution - stored wins, else draft, else device.
library;

import '../../../core/data/datasources/local_storage.dart';
import '../../../core/l10n/app_locale.dart';
import '../../premium/models/personalization_models.dart';
import '../data/onboarding_setup_draft.dart';

abstract final class OnboardingLanguage {
  OnboardingLanguage._();

  static const storageKey = 'settings_language';

  /// Explicit settings_language wins; else draft; else settings/device.
  static String resolve({
    required LocalStorage storage,
    OnboardingSetupDraft? draft,
    PersonalizationSettings? settings,
  }) {
    final stored = storage.getString(storageKey);
    final draftLang = draft?.language;
    return AppLocale.resolvePreferred(
      stored: (stored != null && stored.trim().isNotEmpty)
          ? stored
          : (draftLang != null && draftLang.trim().isNotEmpty
                ? draftLang
                : settings?.language),
      device: AppLocale.readDeviceLocale(),
    );
  }
}
