/// Cold restart: ephemeral storage must promote before onboarding routing read.
/// Incomplete onboarding (with or without draft) must never enter Home.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_onboarding_repository.dart';
import 'package:oracly_new/features/onboarding/data/onboarding_setup_draft.dart';
import 'package:oracly_new/features/onboarding/data/onboarding_setup_draft_store.dart';
import 'package:oracly_new/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/screens/splash/splash_boot.dart';
import 'package:oracly_new/screens/splash/splash_destination.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _destChild(Widget page) => (page as ColoredBox).child!;

OnboardingSetupDraft _sampleDraft({String name = 'Ada'}) {
  return OnboardingSetupDraft(
    updatedAtMillis: DateTime.now().millisecondsSinceEpoch,
    name: name,
    language: 'tr',
    style: AiPersonality.mystical,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'seeded onboarding_completed survives ephemeral cold start after promote',
    () async {
      SharedPreferences.setMockInitialValues({
        LocalOnboardingRepository.completedKey: true,
      });

      // Mirror main.dart: first frame uses ephemeral storage.
      final storage = LocalStorage.ephemeral();
      expect(storage.isEphemeral, isTrue);
      expect(
        storage.getBool(LocalOnboardingRepository.completedKey),
        isNull,
        reason: 'Ephemeral map is empty before promote',
      );

      final completed = await splashResolveOnboardingCompleted(storage);

      expect(completed, isTrue);
      expect(storage.isEphemeral, isFalse);

      final page = SplashDestination.build(
        onboardingCompleted: completed,
        storage: storage,
      );
      expect(page, isA<ColoredBox>());
      expect(_destChild(page), isA<OraclyAppShell>());
    },
  );

  test('fresh install, no draft, incomplete -> Onboarding', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage.ephemeral();

    final completed = await splashResolveOnboardingCompleted(storage);

    expect(completed, isFalse);
    expect(OnboardingSetupDraftStore(storage).load(), isNull);
    final page = SplashDestination.build(
      onboardingCompleted: completed,
      storage: storage,
    );
    expect(_destChild(page), isA<OnboardingScreen>());
    expect(_destChild(page), isNot(isA<OraclyAppShell>()));
  });

  test('incomplete + existing draft -> Onboarding (not Home)', () {
    final draft = _sampleDraft();
    final storage = LocalStorage.ephemeral({
      LocalOnboardingRepository.completedKey: false,
      OnboardingSetupDraftStore.draftKey: jsonEncode(draft.toJson()),
    });

    expect(storage.getBool(LocalOnboardingRepository.completedKey), isFalse);
    expect(OnboardingSetupDraftStore(storage).load(), isNotNull);

    final page = SplashDestination.build(
      onboardingCompleted: false,
      storage: storage,
    );
    expect(_destChild(page), isA<OnboardingScreen>());
    expect(_destChild(page), isNot(isA<OraclyAppShell>()));
  });

  test('completed onboarding -> Home', () {
    final storage = LocalStorage.ephemeral({
      LocalOnboardingRepository.completedKey: true,
    });

    final page = SplashDestination.build(
      onboardingCompleted: true,
      storage: storage,
    );
    expect(_destChild(page), isA<OraclyAppShell>());
  });

  test('cold restart with partial draft must NOT enter Home', () async {
    final draft = OnboardingSetupDraft(
      updatedAtMillis: 1,
      language: 'en',
      style: AiPersonality.mystical,
    );
    SharedPreferences.setMockInitialValues({
      OnboardingSetupDraftStore.draftKey: jsonEncode(draft.toJson()),
    });

    final storage = LocalStorage.ephemeral();
    final completed = await splashResolveOnboardingCompleted(storage);
    expect(completed, isFalse);

    // After promote, durable prefs still have incomplete + draft.
    expect(OnboardingSetupDraftStore(storage).load(), isNotNull);

    final page = SplashDestination.build(
      onboardingCompleted: completed,
      storage: storage,
    );
    expect(
      _destChild(page),
      isA<OnboardingScreen>(),
      reason: 'Partial draft must resume onboarding, never Home',
    );
    expect(_destChild(page), isNot(isA<OraclyAppShell>()));
  });

  test(
    'draft presence never flips completed flag or routes Home',
    () async {
      final draft = _sampleDraft(name: 'Resume');
      SharedPreferences.setMockInitialValues({
        LocalOnboardingRepository.completedKey: false,
        OnboardingSetupDraftStore.draftKey: jsonEncode(draft.toJson()),
      });
      final storage = LocalStorage.ephemeral();
      final completed = await splashResolveOnboardingCompleted(storage);
      expect(completed, isFalse);
      expect(OnboardingSetupDraftStore(storage).load()?.name, 'Resume');
      expect(
        _destChild(
          SplashDestination.build(
            onboardingCompleted: completed,
            storage: storage,
          ),
        ),
        isA<OnboardingScreen>(),
      );
    },
  );
}
