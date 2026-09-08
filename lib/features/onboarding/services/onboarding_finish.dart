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
  required ProviderContainer container,
  required OnboardingSetupDraftStore draftStore,
  String name = '',
  DateTime? birthDate,
  String? birthPlace,
  required String language,
  required AiPersonality style,
}) async {
  // Capture all dependencies while the onboarding WidgetRef is still alive.
  final storage = ref.read(localStorageProvider);
  final starterGrant = ref.read(gemStarterGrantProvider);
  final wallet = ref.read(gemWalletProvider);
  final onboardingRepository = ref.read(onboardingRepositoryProvider);
  final pendingFirstReading = ref.read(firstReadingPendingProvider.notifier);

  await OnboardingCompletion.run(
    persistProfile: () => OnboardingProfileSaver.apply(
      ref,
      container: container,
      name: name,
      birthDate: birthDate,
      birthPlace: birthPlace,
      language: language,
      style: style,
    ),
    requestFirstReading: () => FirstSessionIntent.requestFirstReading(storage),
    grantStarterGems: () async {
      await starterGrant.ensureOnce();
      wallet.reload();
    },
    clearDraft: draftStore.clear,
    markCompleted: onboardingRepository.markCompleted,
  );
  pendingFirstReading.state = true;
  return true;
}
