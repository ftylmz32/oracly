/// SPRINT-004 — Riverpod providers for Personal Insights.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/auth/user_local_data_isolation.dart';
import '../controllers/personal_insights_controller.dart';
import '../data/personal_insights_preferences_repository.dart';
import '../services/personal_insights_experience_service.dart';

final personalInsightsPreferencesRepositoryProvider =
    Provider<PersonalInsightsPreferencesRepository>((ref) {
      return PersonalInsightsPreferencesRepository(
        ref.watch(localStorageProvider),
      );
    });

final personalInsightsExperienceServiceProvider =
    Provider<PersonalInsightsExperienceService>((ref) {
      return PersonalInsightsExperienceService(
        reflectionEngine: ref.watch(reflectionEngineServiceProvider),
        preferences: ref.watch(personalInsightsPreferencesRepositoryProvider),
      );
    });

final personalInsightsControllerProvider =
    ChangeNotifierProvider<PersonalInsightsController>((ref) {
      final controller = PersonalInsightsController(
        ref.watch(personalInsightsExperienceServiceProvider),
      );
      void onOwnerSwitch() => controller.load();
      final epoch = UserLocalDataIsolation.accountSwitchEpoch;
      epoch.addListener(onOwnerSwitch);
      ref.onDispose(() => epoch.removeListener(onOwnerSwitch));
      controller.load();
      return controller;
    });
