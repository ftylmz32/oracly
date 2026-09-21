/// Timing race: persisted pending marker must resolve before Home mounts.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/auth/account_deletion_pending_state.dart';
import 'package:oracly_new/core/auth/account_deletion_service.dart';
import 'package:oracly_new/core/auth/presentation/account_deletion_pending_screen.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_onboarding_repository.dart';
import 'package:oracly_new/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:oracly_new/screens/splash/splash_destination.dart';
import 'package:oracly_new/screens/splash/splash_screen.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AccountDeletionPendingState.resetForTest();
  });

  tearDown(() {
    AccountDeletionPendingState.markClear();
  });

  testWidgets(
    'persisted pending marker: splash first frame never mounts Home '
    'before local gate resolves — pending screen is first destination',
    (tester) async {
      SharedPreferences.setMockInitialValues({
        LocalOnboardingRepository.completedKey: true,
        AccountDeletionService.pendingIdentityCleanupKey: true,
      });

      // Ephemeral first — mirrors main.dart cold start before promote.
      final storage = LocalStorage.ephemeral();
      AccountDeletionPendingState.beginStartup();
      expect(AccountDeletionPendingState.isUnresolved, isTrue);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(storage),
          ],
          child: const MaterialApp(home: SplashScreen()),
        ),
      );

      // First paint: brand/midnight only — gate still unresolved or resolving.
      await tester.pump();
      expect(find.byType(OraclyAppShell), findsNothing);
      expect(find.byType(OnboardingScreen), findsNothing);

      // Allow bootstrap to promote prefs + resolve gate + splash first frame.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 50));
        if (!AccountDeletionPendingState.isUnresolved) break;
      }

      expect(AccountDeletionPendingState.isBlocked, isTrue);
      expect(find.byType(OraclyAppShell), findsNothing);
      expect(find.byType(OnboardingScreen), findsNothing);

      // Destination may mount under overlay once gate + first frame ready.
      expect(
        find.byType(AccountDeletionPendingScreen),
        findsOneWidget,
        reason: 'first real destination must be pending cleanup',
      );
    },
  );

  test('resolveFromLocalStorage is routing-critical and sync after promote',
      () async {
    SharedPreferences.setMockInitialValues({
      AccountDeletionService.pendingIdentityCleanupKey: true,
    });
    final storage = LocalStorage.ephemeral();
    AccountDeletionPendingState.beginStartup();
    expect(AccountDeletionPendingState.isUnresolved, isTrue);

    await AccountDeletionPendingState.resolveFromLocalStorage(storage);

    expect(AccountDeletionPendingState.isBlocked, isTrue);
    expect(storage.isEphemeral, isFalse);
  });

  test('clear marker resolves to clear without network', () async {
    SharedPreferences.setMockInitialValues({
      AccountDeletionService.pendingIdentityCleanupKey: false,
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    AccountDeletionPendingState.beginStartup();
    await AccountDeletionPendingState.resolveFromLocalStorage(storage);
    expect(AccountDeletionPendingState.isClear, isTrue);
  });

  test('SplashDestination.build refuses unresolved gate', () {
    AccountDeletionPendingState.beginStartup();
    expect(
      () => SplashDestination.build(
        onboardingCompleted: true,
        storage: LocalStorage.ephemeral(),
      ),
      throwsA(isA<AssertionError>()),
    );
  });
}
