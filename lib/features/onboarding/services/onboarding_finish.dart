/// Runs guarded onboarding finish and reports success for navigation.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/first_session/first_session_intent.dart';
import '../../gems/providers/gem_providers.dart';
import '../../premium/models/personalization_models.dart';
import '../data/onboarding_setup_draft_store.dart';
import 'onboarding_completion.dart';
import 'onboarding_profile_saver.dart';

Future<bool> finishOnboarding({
  required WidgetRef ref,
  required OnboardingSetupDraftStore draftStore,
  String name = '',
  DateTime? birthDate,
  String? birthPlace,
  required String language,
  required AiPersonality style,
}) async {
  await OnboardingCompletion.run(
    persistProfile: () => OnboardingProfileSaver.apply(
      ref,
      name: name,
      birthDate: birthDate,
      birthPlace: birthPlace,
      language: language,
      style: style,
    ),
    requestFirstReading: () =>
        FirstSessionIntent.requestFirstReading(ref.read(localStorageProvider)),
    grantStarterGems: () async {
      await ref.read(gemStarterGrantProvider).ensureOnce();
      ref.read(gemWalletProvider).reload();
    },
    clearDraft: draftStore.clear,
    markCompleted: () => ref.read(onboardingRepositoryProvider).markCompleted(),
  );
  ref.read(firstReadingPendingProvider.notifier).state = true;
  return true;
}
