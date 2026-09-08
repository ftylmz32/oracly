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
    required ProviderContainer container,
    String name = '',
    DateTime? birthDate,
    String? birthPlace,
    String? language,
    AiPersonality? style,
  }) async {
    // Capture every provider dependency before the first async boundary so
    // onboarding persistence can safely finish even if its screen is removed.
    final profile = ref.read(userProfileProvider.notifier);
    final currentSettings =
        ref.read(settingsProvider).value ?? const PersonalizationSettings();
    final settings = ref.read(settingsProvider.notifier);
    final birthChart = birthDate == null
        ? null
        : ref.read(birthChartExperienceServiceProvider);

    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      await profile.saveName(trimmed);
    }
    if (language != null || style != null) {
      await settings.saveSettings(
        currentSettings.copyWith(language: language, aiPersonality: style),
      );
    }
    if (birthDate == null || birthChart == null) return;
    try {
      await birthChart.generate(
        BirthProfile(
          birthDate: birthDate,
          birthPlace: birthPlace ?? OraclyL10n.t('onboard.birth_unspecified'),
        ),
      );
      container.invalidate(birthInformationProvider);
      PersonalDiscoveryRefresh.invalidateContainer(container);
    } catch (_) {
      // Do not block Home if chart persist fails.
    }
  }
}
