/// Persists optional first-launch profile into canonical stores.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/anonymous_auth_bootstrap.dart';
import '../../../core/data/repositories/local_birth_chart_repository.dart';
import '../../birth_chart/data/pending_birth_profile_store.dart';
import '../../birth_chart/providers/birth_chart_providers.dart';
import '../../birth_chart/providers/birth_information_provider.dart';
import '../../personal_discovery/services/personal_discovery_refresh.dart';
import '../../premium/models/personalization_models.dart';
import 'onboarding_birth_profile.dart';

abstract final class OnboardingProfileSaver {
  OnboardingProfileSaver._();

  static Future<void> apply(
    WidgetRef ref, {
    String name = '',
    DateTime? birthDate,
    String? birthPlace,
    String? language,
    AiPersonality? style,
    DateTime? birthTime,
    bool birthTimeKnown = false,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isNotEmpty) {
      await ref.read(userProfileProvider.notifier).saveName(trimmed);
    }
    await _settings(ref, language: language, style: style);
    if (birthDate == null) return;
    final profile = OnboardingBirthProfile.build(
      birthDate: birthDate,
      birthPlace: birthPlace,
      birthTime: birthTime,
      birthTimeKnown: birthTimeKnown,
    );
    final pending = PendingBirthProfileStore(ref.read(localStorageProvider));
    // The chart store is owner-scoped; a cold start may not have one yet.
    await AnonymousAuthBootstrap.ensure(ref.read(authServiceProvider));
    try {
      await ref.read(birthChartExperienceServiceProvider).generate(profile);
      await pending.clear();
    } on BirthChartOwnerUnavailableException {
      // Kept for the first owned chart read instead of asking again.
      await pending.save(profile);
    } catch (_) {
      // Do not block Home if chart persist fails.
    }
    ref.invalidate(birthInformationProvider);
    ref.invalidate(savedNatalEvidenceProvider);
    PersonalDiscoveryRefresh.invalidate(ref);
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
