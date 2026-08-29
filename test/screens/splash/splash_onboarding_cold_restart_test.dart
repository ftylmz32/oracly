/// Cold restart: ephemeral storage must promote before onboarding routing read.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_onboarding_repository.dart';
import 'package:oracly_new/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:oracly_new/screens/splash/splash_boot.dart';
import 'package:oracly_new/screens/splash/splash_destination.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      expect((page as ColoredBox).child, isA<OraclyAppShell>());
    },
  );

  test('fresh install ephemeral boot stays incomplete after promote', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage.ephemeral();

    final completed = await splashResolveOnboardingCompleted(storage);

    expect(completed, isFalse);
    final page = SplashDestination.build(
      onboardingCompleted: completed,
      storage: storage,
    );
    expect((page as ColoredBox).child, isA<OnboardingScreen>());
  });
}
