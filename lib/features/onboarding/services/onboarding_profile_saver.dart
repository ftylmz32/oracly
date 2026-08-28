/// Persists optional first-launch profile into canonical stores.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/l10n/l10n.dart';
import '../../birth_chart/models/birth_profile.dart';
import '../../birth_chart/providers/birth_chart_providers.dart';
import '../../birth_chart/providers/birth_information_provider.dart';
import '../../personal_discovery/services/personal_discovery_refresh.dart';
import '../../premium/models/personalization_models.dart';

abstract final class OnboardingProfileSaver {
  OnboardingProfileSaver._();

  static Future<void> apply(
    WidgetRef ref, {
    String name = '',
    DateTime? birthDate,
    String? birthPlace,
    String? language,
    AiPersonality? style,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      await ref.read(userProfileProvider.notifier).saveName(trimmed);
    }
    await _settings(ref, language: language, style: style);
    if (birthDate == null) return;
    try {
      await ref
          .read(birthChartExperienceServiceProvider)
          .generate(
            BirthProfile(
              birthDate: birthDate,
              birthPlace: birthPlace ?? OraclyL10n.t('onboard.birth_unspecified'),
            ),
          );
      ref.invalidate(birthInformationProvider);
      PersonalDiscoveryRefresh.invalidate(ref);
    } catch (_) {
      // Do not block Home if chart persist fails.
    }
  }

  static Future<void> _settings(
    WidgetRef ref, {
    String? language,
    AiPersonality? style,
  }) async {
    if (language == null && style == null) return;
    final current =
        ref.read(settingsProvider).value ?? const PersonalizationSettings();
    await ref
        .read(settingsProvider.notifier)
        .saveSettings(
          current.copyWith(language: language, aiPersonality: style),
        );
  }
}
