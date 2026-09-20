/// Durable storage gate: CLEAR only after proven durable read.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/auth/account_deletion_owner_bootstrap.dart';
import 'package:oracly_new/core/auth/account_deletion_pending_state.dart';
import 'package:oracly_new/core/auth/account_deletion_service.dart';
import 'package:oracly_new/core/auth/presentation/account_deletion_pending_screen.dart';
import 'package:oracly_new/core/auth/presentation/secure_startup_recovery_screen.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/datasources/unpromotable_local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_onboarding_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/privacy/copy/privacy_control_copy.dart';
import 'package:oracly_new/screens/splash/splash_destination.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _child(Widget page) => (page as ColoredBox).child!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AccountDeletionPendingState.beginStartup();
  });

  tearDown(() {
    AccountDeletionPendingState.markClear();
  });

  test('durable prefs + no marker → clear', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final status =
        await AccountDeletionPendingState.resolveFromLocalStorage(storage);
    expect(status, AccountDeletionGateResolveStatus.clear);
    expect(AccountDeletionPendingState.isClear, isTrue);
  });

  test('durable prefs + identity marker → blocked', () async {
    SharedPreferences.setMockInitialValues({
      AccountDeletionService.pendingIdentityCleanupKey: true,
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final status =
        await AccountDeletionPendingState.resolveFromLocalStorage(storage);
    expect(status, AccountDeletionGateResolveStatus.blocked);
    expect(AccountDeletionPendingState.isBlocked, isTrue);
  });

  test('durable prefs + anonymous bootstrap marker → finalizing', () async {
    SharedPreferences.setMockInitialValues({
      AccountDeletionService.pendingAnonymousBootstrapKey: true,
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final status =
        await AccountDeletionPendingState.resolveFromLocalStorage(storage);
    expect(status, AccountDeletionGateResolveStatus.finalizing);
    expect(AccountDeletionPendingState.isFinalizing, isTrue);
  });

  test('promote fails → storageUnavailable, never clear', () async {
    final storage = UnpromotableLocalStorage();
    final status =
        await AccountDeletionPendingState.resolveFromLocalStorage(storage);
    expect(status, AccountDeletionGateResolveStatus.storageUnavailable);
    expect(AccountDeletionPendingState.isStorageUnavailable, isTrue);
    expect(AccountDeletionPendingState.isClear, isFalse);
    expect(AccountDeletionPendingState.allowsOwnerBoundExperience, isFalse);
  });

  test('storageUnavailable routes to recovery — not Home or pending claim',
      () async {
    SharedPreferences.setMockInitialValues({
      LocalOnboardingRepository.completedKey: true,
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    AccountDeletionPendingState.markStorageUnavailable();

    final page = SplashDestination.build(
      onboardingCompleted: true,
      storage: storage,
    );
    expect(_child(page), isA<SecureStartupRecoveryScreen>());
    expect(_child(page), isNot(isA<OraclyAppShell>()));
    expect(_child(page), isNot(isA<AccountDeletionPendingScreen>()));
  });

  testWidgets('recovery screen copy does not claim pending deletion',
      (tester) async {
    AccountDeletionPendingState.markStorageUnavailable();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(LocalStorage.ephemeral()),
        ],
        child: const MaterialApp(home: SecureStartupRecoveryScreen()),
      ),
    );
    expect(find.text(PrivacyControlCopy.storageRecoveryTitle), findsOneWidget);
    expect(find.text(PrivacyControlCopy.deletePendingTitle), findsNothing);
  });

  test('storage unavailable then retry succeeds → clear', () async {
    SharedPreferences.setMockInitialValues({});
    var storage = UnpromotableLocalStorage() as LocalStorage;
    await AccountDeletionPendingState.resolveFromLocalStorage(storage);
    expect(AccountDeletionPendingState.isStorageUnavailable, isTrue);

    storage = LocalStorage(await SharedPreferences.getInstance());
    final status =
        await AccountDeletionPendingState.resolveFromLocalStorage(storage);
    expect(status, AccountDeletionGateResolveStatus.clear);
  });

  test('storage unavailable then retry succeeds → blocked', () async {
    SharedPreferences.setMockInitialValues({
      AccountDeletionService.pendingIdentityCleanupKey: true,
    });
    var storage = UnpromotableLocalStorage() as LocalStorage;
    await AccountDeletionPendingState.resolveFromLocalStorage(storage);

    storage = LocalStorage(await SharedPreferences.getInstance());
    final status =
        await AccountDeletionPendingState.resolveFromLocalStorage(storage);
    expect(status, AccountDeletionGateResolveStatus.blocked);
  });

  test('blocked: Premium warm count stays 0', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final premium = _CountingPremium(storage);
    AccountDeletionPendingState.markBlocked();
    await AccountDeletionOwnerBootstrap.warmPremiumIfClear(premium);
    expect(premium.warmCount, 0);
  });

  test('storageUnavailable: Premium warm count stays 0', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final premium = _CountingPremium(storage);
    AccountDeletionPendingState.markStorageUnavailable();
    await AccountDeletionOwnerBootstrap.warmPremiumIfClear(premium);
    expect(premium.warmCount, 0);
  });

  test('clear: Premium warm still runs', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final premium = _CountingPremium(storage);
    AccountDeletionPendingState.markClear();
    await AccountDeletionOwnerBootstrap.warmPremiumIfClear(premium);
    expect(premium.warmCount, 1);
  });
}

class _CountingPremium extends MockPremiumRepository {
  _CountingPremium(super.storage)
      : super(secureStorage: InMemorySecureStorage());

  int warmCount = 0;

  @override
  Future<void> warmCredentialCache() async {
    warmCount++;
    await super.warmCredentialCache();
  }
}
