/// Pending deletion blocks Home and owner-bound hydration.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/account_deletion_pending_state.dart';
import 'package:oracly_new/core/auth/presentation/account_deletion_pending_screen.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_onboarding_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/intelligence/data/personal_memory_store.dart';
import 'package:oracly_new/core/services/premium_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:oracly_new/features/privacy/copy/privacy_control_copy.dart';
import 'package:oracly_new/screens/splash/splash_destination.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _child(Widget page) => (page as ColoredBox).child!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AccountDeletionPendingState.isBlocked.value = false;
  });

  tearDown(() {
    AccountDeletionPendingState.isBlocked.value = false;
  });

  test('pending deletion routes to completion screen — not Home', () async {
    SharedPreferences.setMockInitialValues({
      LocalOnboardingRepository.completedKey: true,
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    AccountDeletionPendingState.isBlocked.value = true;

    final page = SplashDestination.build(
      onboardingCompleted: true,
      storage: storage,
    );

    expect(_child(page), isA<AccountDeletionPendingScreen>());
    expect(_child(page), isNot(isA<OraclyAppShell>()));
    expect(_child(page), isNot(isA<OnboardingScreen>()));
  });

  test('without pending, completed onboarding still reaches Home', () async {
    SharedPreferences.setMockInitialValues({
      LocalOnboardingRepository.completedKey: true,
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());

    final page = SplashDestination.build(
      onboardingCompleted: true,
      storage: storage,
    );

    expect(_child(page), isA<OraclyAppShell>());
  });

  testWidgets('pending screen shows completion copy', (tester) async {
    AccountDeletionPendingState.isBlocked.value = true;
    await tester.pumpWidget(
      const MaterialApp(home: AccountDeletionPendingScreen()),
    );
    expect(find.text(PrivacyControlCopy.deletePendingTitle), findsOneWidget);
    expect(find.text(PrivacyControlCopy.deletePendingRetry), findsOneWidget);
  });

  test(
    'while blocked, PremiumService denies entitlement even if cache is active',
    () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final secure = InMemorySecureStorage();
      final premium = MockPremiumRepository(storage, secureStorage: secure);
      await premium.activatePlan(PremiumPlanKind.yearly, authoritative: true);
      final service = PremiumService(premium, MockUserRepository(storage));

      expect(premium.isActiveNow, isTrue);
      AccountDeletionPendingState.isBlocked.value = true;
      expect(service.isActiveNow, isFalse);
      expect(await service.isActive(), isFalse);
    },
  );

  test('while blocked, owner-bound memory and gem cache remain but Home is gated',
      () async {
    SharedPreferences.setMockInitialValues({
      LocalOnboardingRepository.completedKey: true,
      PersonalMemoryStore.key: 'secret-memory',
      GemWalletStore.balanceKey: 42,
      GemWalletStore.serverBalanceOwnerKey: 'deleted-owner',
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    AccountDeletionPendingState.isBlocked.value = true;

    // Data is intentionally not wiped yet (identity still present).
    expect(storage.getString(PersonalMemoryStore.key), 'secret-memory');
    expect(storage.getInt(GemWalletStore.balanceKey), 42);

    final page = SplashDestination.build(
      onboardingCompleted: true,
      storage: storage,
    );
    expect(_child(page), isA<AccountDeletionPendingScreen>());
  });
}
