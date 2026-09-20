/// Durable storage gate: CLEAR only after proven durable read.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/auth/account_deletion_owner_bootstrap.dart';
import 'package:oracly_new/core/auth/account_deletion_pending_state.dart';
import 'package:oracly_new/core/auth/account_deletion_service.dart';
import 'package:oracly_new/core/auth/mock_auth_service.dart';
import 'package:oracly_new/core/auth/presentation/account_deletion_pending_screen.dart';
import 'package:oracly_new/core/auth/presentation/secure_startup_recovery_screen.dart';
import 'package:oracly_new/core/auth/session_manager.dart';
import 'package:oracly_new/core/auth/token_manager.dart';
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

  group(
    'integrated startup regression — resolveAndReconcile is the REAL '
    'sequence main._deferredStartup calls, not a re-implementation of it',
    () {
      AccountDeletionService buildDeletion(LocalStorage storage) {
        return AccountDeletionService(
          auth: MockAuthService(),
          storage: storage,
          secureStorage: InMemorySecureStorage(),
          deleteServerData: () async => true,
        );
      }

      test(
        'REGRESSION (P0): an unpromotable storage must NEVER let the gate '
        'become clear via an empty-ephemeral marker re-read — this is the '
        'exact bug an independent review found in the previous version of '
        'main._deferredStartup',
        () async {
          final storage = UnpromotableLocalStorage();

          await AccountDeletionPendingState.resolveAndReconcile(
            storage,
            buildDeletion(storage),
          );

          expect(
            AccountDeletionPendingState.isStorageUnavailable,
            isTrue,
            reason: 'must stay storageUnavailable — must NOT have been '
                'overwritten to clear by re-reading markers through the '
                'same empty ephemeral storage',
          );
          expect(AccountDeletionPendingState.allowsOwnerBoundExperience, isFalse);
        },
      );

      test(
        'durable storage with no pending markers resolves clear through the '
        'exact same real sequence',
        () async {
          SharedPreferences.setMockInitialValues({});
          final storage = LocalStorage(await SharedPreferences.getInstance());

          await AccountDeletionPendingState.resolveAndReconcile(
            storage,
            buildDeletion(storage),
          );

          expect(AccountDeletionPendingState.isClear, isTrue);
        },
      );

      test(
        'a pending identity-cleanup marker that the automatic retry CAN '
        'resolve (identity actually deletable now) legitimately clears — '
        'proving resolveAndReconcile only ever derives "clear" from a real '
        'successful outcome, never from an untrusted empty read',
        () async {
          SharedPreferences.setMockInitialValues({
            AccountDeletionService.pendingIdentityCleanupKey: true,
          });
          final storage = LocalStorage(await SharedPreferences.getInstance());
          final auth = MockAuthService(
            sessions: InMemorySessionManager(_NoopTokens()),
          );
          await auth.signInAnonymously();
          final deletion = AccountDeletionService(
            auth: auth,
            storage: storage,
            secureStorage: InMemorySecureStorage(),
            deleteServerData: () async => true,
          );

          await AccountDeletionPendingState.resolveAndReconcile(
            storage,
            deletion,
          );

          expect(AccountDeletionPendingState.isClear, isTrue);
          expect(deletion.hasPendingIdentityCleanup, isFalse);
        },
      );
    },
  );

  group('malformed marker types must not fail open', () {
    test('identity marker stored as String → NOT clear', () async {
      final storage = LocalStorage.ephemeral({
        AccountDeletionService.pendingIdentityCleanupKey: 'true',
      });
      final status =
          await AccountDeletionPendingState.resolveFromLocalStorage(storage);
      expect(status, isNot(AccountDeletionGateResolveStatus.clear));
    });

    test('identity marker stored as int → NOT clear', () async {
      final storage = LocalStorage.ephemeral({
        AccountDeletionService.pendingIdentityCleanupKey: 1,
      });
      final status =
          await AccountDeletionPendingState.resolveFromLocalStorage(storage);
      expect(status, isNot(AccountDeletionGateResolveStatus.clear));
    });

    test('anonymous-bootstrap marker stored as String → NOT clear', () async {
      final storage = LocalStorage.ephemeral({
        AccountDeletionService.pendingAnonymousBootstrapKey: 'true',
      });
      final status =
          await AccountDeletionPendingState.resolveFromLocalStorage(storage);
      expect(status, isNot(AccountDeletionGateResolveStatus.clear));
    });

    test('both markers genuinely false → clear', () async {
      final storage = LocalStorage.ephemeral({
        AccountDeletionService.pendingIdentityCleanupKey: false,
        AccountDeletionService.pendingAnonymousBootstrapKey: false,
      });
      final status =
          await AccountDeletionPendingState.resolveFromLocalStorage(storage);
      expect(status, AccountDeletionGateResolveStatus.clear);
    });

    test('both markers absent → clear', () async {
      final storage = LocalStorage.ephemeral();
      final status =
          await AccountDeletionPendingState.resolveFromLocalStorage(storage);
      expect(status, AccountDeletionGateResolveStatus.clear);
    });

    test(
      'AccountDeletionService.hasPendingIdentityCleanup also fails closed '
      'on a corrupt marker (the same bug existed independently here)',
      () async {
        final storage = LocalStorage.ephemeral({
          AccountDeletionService.pendingIdentityCleanupKey: 42,
        });
        final deletion = AccountDeletionService(
          auth: MockAuthService(),
          storage: storage,
          secureStorage: InMemorySecureStorage(),
          deleteServerData: () async => true,
        );
        expect(deletion.hasPendingIdentityCleanup, isTrue);
      },
    );
  });

  group('canonical post-gate owner startup coordinator', () {
    ProviderContainer buildContainer(LocalStorage storage) {
      return ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          secureStorageProvider.overrideWithValue(InMemorySecureStorage()),
          premiumRepositoryProvider.overrideWithValue(
            _CountingPremium(storage),
          ),
          authServiceProvider.overrideWithValue(MockAuthService()),
        ],
      );
    }

    test(
      'runIfClear is a no-op (does not warm Premium) when the gate is not '
      'clear',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = LocalStorage(await SharedPreferences.getInstance());
        final container = buildContainer(storage);
        addTearDown(container.dispose);
        AccountDeletionPendingState.markBlocked();

        final outcome = await AccountDeletionOwnerBootstrap.runIfClear(
          container,
        );

        expect(outcome, OwnerStartupOutcome.skippedNotClear);
        final premium =
            container.read(premiumRepositoryProvider) as _CountingPremium;
        expect(premium.warmCount, 0);
      },
    );

    test(
      'runIfClear runs the full pipeline (Premium warm at least) when the '
      'gate is clear — the same pipeline a normal cold start and a '
      'successful storage recovery both resume',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = LocalStorage(await SharedPreferences.getInstance());
        final container = buildContainer(storage);
        addTearDown(container.dispose);
        AccountDeletionPendingState.markClear();

        final outcome = await AccountDeletionOwnerBootstrap.runIfClear(
          container,
        );

        expect(outcome, OwnerStartupOutcome.completed);
        final premium =
            container.read(premiumRepositoryProvider) as _CountingPremium;
        expect(premium.warmCount, 1);
      },
    );

    test(
      'concurrent runIfClear calls single-flight — Premium is warmed once, '
      'not twice, for two overlapping callers (main + storage-recovery race)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = LocalStorage(await SharedPreferences.getInstance());
        final container = buildContainer(storage);
        addTearDown(container.dispose);
        AccountDeletionPendingState.markClear();

        final results = await Future.wait([
          AccountDeletionOwnerBootstrap.runIfClear(container),
          AccountDeletionOwnerBootstrap.runIfClear(container),
        ]);

        expect(results, everyElement(OwnerStartupOutcome.completed));
        final premium =
            container.read(premiumRepositoryProvider) as _CountingPremium;
        expect(
          premium.warmCount,
          1,
          reason: 'single-flight must prevent a second concurrent owner '
              'bootstrap from running the pipeline again',
        );
      },
    );
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

class _NoopTokens implements TokenManager {
  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async => null;
  @override
  Future<String?> getRefreshToken() async => null;
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {}
  @override
  Future<void> clearTokens() async {}
  @override
  Future<bool> hasValidAccessToken() async => false;
}
