/// Durable storage gate: CLEAR only after proven durable read.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/auth/account_deletion_finalizer.dart';
import 'package:oracly_new/core/auth/account_deletion_markers.dart';
import 'package:oracly_new/core/auth/account_deletion_owner_bootstrap.dart';
import 'package:oracly_new/core/auth/account_deletion_pending_state.dart';
import 'package:oracly_new/core/auth/account_deletion_service.dart';
import 'package:oracly_new/core/auth/account_deletion_target.dart';
import 'package:oracly_new/core/auth/auth_service.dart';
import 'package:oracly_new/core/auth/mock_auth_service.dart';
import 'package:oracly_new/core/auth/models/account_reauth_method.dart';
import 'package:oracly_new/core/auth/models/auth_credentials.dart';
import 'package:oracly_new/core/auth/models/auth_session.dart';
import 'package:oracly_new/core/auth/presentation/account_deletion_pending_screen.dart';
import 'package:oracly_new/core/auth/presentation/account_integrity_recovery_screen.dart';
import 'package:oracly_new/core/auth/presentation/secure_startup_recovery_screen.dart';
import 'package:oracly_new/core/auth/session_manager.dart';
import 'package:oracly_new/core/auth/token_manager.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/datasources/unpromotable_local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_onboarding_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/network/api_result.dart';
import 'package:oracly_new/core/network/network_exception.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/gems/controllers/gem_wallet_controller.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/providers/gem_providers.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_coordinator.dart';
import 'package:oracly_new/features/privacy/copy/privacy_control_copy.dart';
import 'package:oracly_new/screens/splash/splash_boot.dart';
import 'package:oracly_new/screens/splash/splash_destination.dart';
import 'package:oracly_new/shared/navigation/oracly_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/test_path_provider.dart';

Widget _child(Widget page) => (page as ColoredBox).child!;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    AccountDeletionPendingState.resetForTest();
    await installTestPathProvider('oracly-gate-');
  });

  tearDown(() {
    AccountDeletionPendingState.markClear();
    AccountDeletionPendingState.resetForTest();
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

  test(
      'STARTUP A: durable prefs + ONLY pendingLocalWipe=true → finalizing, '
      'never clear — the identity is already gone and only local cleanup '
      'remains, exactly the state anonymousBootstrapPending represents',
      () async {
    SharedPreferences.setMockInitialValues({
      AccountDeletionService.pendingLocalWipeKey: true,
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final status =
        await AccountDeletionPendingState.resolveFromLocalStorage(storage);
    expect(status, AccountDeletionGateResolveStatus.finalizing);
    expect(AccountDeletionPendingState.isFinalizing, isTrue);
    expect(AccountDeletionPendingState.allowsOwnerBoundExperience, isFalse);
    expect(AccountDeletionPendingState.blocksDeepLinks, isTrue);
  });

  test(
      'STARTUP B: with ONLY pendingLocalWipe=true, the same resolve+mount '
      'sequence SplashEntryBootstrap actually runs (resolveFromLocalStorage '
      'then building the destination from the resulting phase) never '
      'produces an owner-bound destination', () async {
    SharedPreferences.setMockInitialValues({
      AccountDeletionService.pendingLocalWipeKey: true,
      LocalOnboardingRepository.completedKey: true,
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());

    // Exactly splashEntryBootstrap's own first two steps, in order.
    await AccountDeletionPendingState.resolveFromLocalStorage(storage);
    final destination = SplashDestination.build(
      onboardingCompleted: true,
      storage: storage,
    );

    final mounted = _child(destination);
    expect(
      mounted,
      isNot(isA<OraclyAppShell>()),
      reason: 'no Home/owner-bound destination may mount before cleanup '
          'reconciliation notices the local-wipe marker',
    );
    expect(AccountDeletionPendingState.isFinalizing, isTrue);
  });

  test(
      'STARTUP D: pendingLocalWipe=true AND pendingIdentityCleanup=true → '
      'finalizing, never clear, never blocked — finalizing (a real '
      'deletion known to exist) takes precedence over blocked (identity '
      'might still need destructive work)', () async {
    SharedPreferences.setMockInitialValues({
      AccountDeletionService.pendingLocalWipeKey: true,
      AccountDeletionService.pendingIdentityCleanupKey: true,
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final status =
        await AccountDeletionPendingState.resolveFromLocalStorage(storage);
    expect(status, AccountDeletionGateResolveStatus.finalizing);
    expect(AccountDeletionPendingState.isFinalizing, isTrue);
    expect(AccountDeletionPendingState.isBlocked, isFalse);
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

  test('integrityRecovery routes to the integrity screen — not Home, not '
      'the pending-deletion claim, not the storage-unavailable screen',
      () async {
    SharedPreferences.setMockInitialValues({
      LocalOnboardingRepository.completedKey: true,
    });
    final storage = LocalStorage(await SharedPreferences.getInstance());
    AccountDeletionPendingState.markIntegrityRecovery();

    final page = SplashDestination.build(
      onboardingCompleted: true,
      storage: storage,
    );
    expect(_child(page), isA<AccountIntegrityRecoveryScreen>());
    expect(_child(page), isNot(isA<OraclyAppShell>()));
    expect(_child(page), isNot(isA<AccountDeletionPendingScreen>()));
    expect(_child(page), isNot(isA<SecureStartupRecoveryScreen>()));
  });

  testWidgets(
      'integrity recovery screen copy does not claim pending deletion and '
      'exposes an explicit (not automatic) destructive continue action',
      (tester) async {
    AccountDeletionPendingState.markIntegrityRecovery();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(LocalStorage.ephemeral()),
        ],
        child: const MaterialApp(home: AccountIntegrityRecoveryScreen()),
      ),
    );
    expect(
      find.text(PrivacyControlCopy.integrityRecoveryTitle),
      findsOneWidget,
    );
    expect(find.text(PrivacyControlCopy.deletePendingTitle), findsNothing);
    expect(
      find.text(PrivacyControlCopy.integrityRecoveryContinueDeletion),
      findsOneWidget,
    );
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
          deleteServerData: (_) async => true,
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
          await storage.setString(
            AccountDeletionTarget.targetUidKey,
            auth.currentUserId!,
          );
          final deletion = AccountDeletionService(
            auth: auth,
            storage: storage,
            secureStorage: InMemorySecureStorage(),
            deleteServerData: (_) async => true,
          );

          await AccountDeletionPendingState.resolveAndReconcile(
            storage,
            deletion,
          );

          expect(AccountDeletionPendingState.isClear, isTrue);
          expect(deletion.hasPendingIdentityCleanup, isFalse);
        },
      );

      test(
        'STARTUP E: a pending LOCAL-WIPE marker that a restart retry can '
        'resolve (storage is healthy now) completes the wipe, bootstraps a '
        'fresh anonymous owner, and only THEN clears the gate',
        () async {
          SharedPreferences.setMockInitialValues({
            AccountDeletionService.pendingLocalWipeKey: true,
            MockUserRepository.readingLedgerIdsKey: ['old-owner-r1'],
          });
          final storage = LocalStorage(await SharedPreferences.getInstance());
          final auth = MockAuthService(
            sessions: InMemorySessionManager(_NoopTokens()),
          );
          await auth.signInAnonymously();
          await storage.setString(
            AccountDeletionTarget.targetUidKey,
            auth.currentUserId!,
          );
          // Local-wipe phase assumes the old Firebase identity is already gone.
          await auth.signOut();
          final deletion = AccountDeletionService(
            auth: auth,
            storage: storage,
            secureStorage: InMemorySecureStorage(),
            deleteServerData: (_) async => true,
          );

          await AccountDeletionPendingState.resolveAndReconcile(
            storage,
            deletion,
          );

          expect(AccountDeletionPendingState.isClear, isTrue);
          expect(deletion.hasPendingLocalWipe, isFalse);
          expect(deletion.hasPendingAnonymousBootstrap, isFalse);
          expect(deletion.hasPendingIdentityCleanup, isFalse);
          expect(
            storage.getStringList(MockUserRepository.readingLedgerIdsKey),
            isNull,
            reason: 'the residual ledger must be gone once the gate is '
                'genuinely clear',
          );
        },
      );
    },
  );

  group('malformed marker types must not fail open (routing)', () {
    test('identity marker stored as String → integrityRecovery, NOT clear',
        () async {
      final storage = LocalStorage.ephemeral({
        AccountDeletionService.pendingIdentityCleanupKey: 'true',
      });
      final status =
          await AccountDeletionPendingState.resolveFromLocalStorage(storage);
      expect(status, AccountDeletionGateResolveStatus.integrityRecovery);
      expect(AccountDeletionPendingState.isIntegrityRecovery, isTrue);
      expect(AccountDeletionPendingState.allowsOwnerBoundExperience, isFalse);
    });

    test('identity marker stored as int → integrityRecovery, NOT clear',
        () async {
      final storage = LocalStorage.ephemeral({
        AccountDeletionService.pendingIdentityCleanupKey: 1,
      });
      final status =
          await AccountDeletionPendingState.resolveFromLocalStorage(storage);
      expect(status, AccountDeletionGateResolveStatus.integrityRecovery);
    });

    test(
        'anonymous-bootstrap marker stored as String → integrityRecovery, '
        'NOT clear, NOT finalizing', () async {
      final storage = LocalStorage.ephemeral({
        AccountDeletionService.pendingAnonymousBootstrapKey: 'true',
      });
      final status =
          await AccountDeletionPendingState.resolveFromLocalStorage(storage);
      expect(status, AccountDeletionGateResolveStatus.integrityRecovery);
      expect(AccountDeletionPendingState.isFinalizing, isFalse);
    });

    test(
        'anonymous-bootstrap marker stored as a double (a real type '
        'SharedPreferences natively supports, just wrong for a bool marker) '
        '→ integrityRecovery, NOT clear', () async {
      SharedPreferences.setMockInitialValues({
        AccountDeletionService.pendingAnonymousBootstrapKey: 3.14,
      });
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final status =
          await AccountDeletionPendingState.resolveFromLocalStorage(storage);
      expect(status, AccountDeletionGateResolveStatus.integrityRecovery);
    });

    test(
        'identity marker corrupt takes priority over a genuinely-true '
        'anonymous marker — corrupt on EITHER key must never be masked',
        () async {
      final storage = LocalStorage.ephemeral({
        AccountDeletionService.pendingIdentityCleanupKey: 'true',
        AccountDeletionService.pendingAnonymousBootstrapKey: true,
      });
      final status =
          await AccountDeletionPendingState.resolveFromLocalStorage(storage);
      expect(status, AccountDeletionGateResolveStatus.integrityRecovery);
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
        'STARTUP: pendingServerDeleteKey stored as String → integrityRecovery',
        () async {
      final storage = LocalStorage.ephemeral({
        AccountDeletionService.pendingServerDeleteKey: 'true',
      });
      final status =
          await AccountDeletionPendingState.resolveFromLocalStorage(storage);
      expect(status, AccountDeletionGateResolveStatus.integrityRecovery);
    });

    test(
        'STARTUP: pendingServerDeleteKey genuinely true → blocked '
        '(never clear, never Home)',
        () async {
      final storage = LocalStorage.ephemeral({
        AccountDeletionService.pendingServerDeleteKey: true,
      });
      final status =
          await AccountDeletionPendingState.resolveFromLocalStorage(storage);
      expect(status, AccountDeletionGateResolveStatus.blocked);
      expect(AccountDeletionPendingState.allowsOwnerBoundExperience, isFalse);
    });

    test(
        'STARTUP C: local-wipe marker stored as String → integrityRecovery, '
        'NOT clear, NOT finalizing — a corrupt marker must never be ignored '
        'and must never authorize local wipe/destructive work', () async {
      final storage = LocalStorage.ephemeral({
        AccountDeletionService.pendingLocalWipeKey: 'true',
      });
      final status =
          await AccountDeletionPendingState.resolveFromLocalStorage(storage);
      expect(status, AccountDeletionGateResolveStatus.integrityRecovery);
      expect(AccountDeletionPendingState.isFinalizing, isFalse);
      expect(AccountDeletionPendingState.allowsOwnerBoundExperience, isFalse);
    });

    test(
        'STARTUP C: local-wipe marker stored as int → integrityRecovery, '
        'NOT clear', () async {
      final storage = LocalStorage.ephemeral({
        AccountDeletionService.pendingLocalWipeKey: 1,
      });
      final status =
          await AccountDeletionPendingState.resolveFromLocalStorage(storage);
      expect(status, AccountDeletionGateResolveStatus.integrityRecovery);
    });

    test(
        'local-wipe marker corrupt takes priority over genuinely-true '
        'identity AND anonymous-bootstrap markers — corrupt on ANY of the '
        'three must never be masked by true values on the others',
        () async {
      final storage = LocalStorage.ephemeral({
        AccountDeletionService.pendingLocalWipeKey: 'true',
        AccountDeletionService.pendingIdentityCleanupKey: true,
        AccountDeletionService.pendingAnonymousBootstrapKey: true,
      });
      final status =
          await AccountDeletionPendingState.resolveFromLocalStorage(storage);
      expect(status, AccountDeletionGateResolveStatus.integrityRecovery);
    });

    test('all three markers genuinely false → clear', () async {
      final storage = LocalStorage.ephemeral({
        AccountDeletionService.pendingServerDeleteKey: false,
        AccountDeletionService.pendingIdentityCleanupKey: false,
        AccountDeletionService.pendingLocalWipeKey: false,
        AccountDeletionService.pendingAnonymousBootstrapKey: false,
      });
      final status =
          await AccountDeletionPendingState.resolveFromLocalStorage(storage);
      expect(status, AccountDeletionGateResolveStatus.clear);
    });
  });

  group(
    'P0 — corrupt marker must never authorize destructive work '
    '(destructive authority is EXACT true only, never corrupt)',
    () {
      test(
        'AccountDeletionService.hasPendingIdentityCleanup is FALSE on a '
        'corrupt marker — corrupt must never authorize destructive work, '
        'even though it is unsafe to treat as clear for routing',
        () async {
          final storage = LocalStorage.ephemeral({
            AccountDeletionService.pendingIdentityCleanupKey: 42,
          });
          final deletion = AccountDeletionService(
            auth: MockAuthService(),
            storage: storage,
            secureStorage: InMemorySecureStorage(),
            deleteServerData: (_) async => true,
          );
          expect(deletion.hasPendingIdentityCleanup, isFalse);
          expect(deletion.hasCorruptDeletionMarker, isTrue);
        },
      );

      test(
        'AccountDeletionService.hasPendingAnonymousBootstrap is FALSE on a '
        'corrupt marker',
        () async {
          final storage = LocalStorage.ephemeral({
            AccountDeletionService.pendingAnonymousBootstrapKey: 'true',
          });
          final deletion = AccountDeletionService(
            auth: MockAuthService(),
            storage: storage,
            secureStorage: InMemorySecureStorage(),
            deleteServerData: (_) async => true,
          );
          expect(deletion.hasPendingAnonymousBootstrap, isFalse);
          expect(deletion.hasCorruptDeletionMarker, isTrue);
        },
      );

      test(
        'identity marker corrupt (String) + current identity exists: '
        'startup resolveAndReconcile performs ZERO destructive work and '
        'lands on integrityRecovery, never blocked/finalizing/clear',
        () async {
          final storage = LocalStorage.ephemeral({
            AccountDeletionService.pendingIdentityCleanupKey: 'true',
          });
          final auth = _CountingAuth();
          final server = _CountingServerDelete();
          final deletion = AccountDeletionService(
            auth: auth,
            storage: storage,
            secureStorage: InMemorySecureStorage(),
            deleteServerData: server.call,
          );

          await AccountDeletionPendingState.resolveAndReconcile(
            storage,
            deletion,
          );

          expect(AccountDeletionPendingState.isIntegrityRecovery, isTrue);
          expect(auth.deleteAccountCalls, 0);
          expect(auth.ensureAnonymousSessionCalls, 0);
          expect(server.calls, 0);
          expect(
            AccountDeletionMarkers.read(
              storage,
              AccountDeletionService.pendingIdentityCleanupKey,
            ),
            MarkerRead.corrupt,
            reason: 'the corrupt marker must not be silently mutated',
          );
        },
      );

      test(
        'identity marker corrupt (int): startup resolveAndReconcile '
        'performs ZERO destructive work',
        () async {
          final storage = LocalStorage.ephemeral({
            AccountDeletionService.pendingIdentityCleanupKey: 1,
          });
          final auth = _CountingAuth();
          final server = _CountingServerDelete();
          final deletion = AccountDeletionService(
            auth: auth,
            storage: storage,
            secureStorage: InMemorySecureStorage(),
            deleteServerData: server.call,
          );

          await AccountDeletionPendingState.resolveAndReconcile(
            storage,
            deletion,
          );

          expect(AccountDeletionPendingState.isIntegrityRecovery, isTrue);
          expect(auth.deleteAccountCalls, 0);
          expect(auth.ensureAnonymousSessionCalls, 0);
          expect(server.calls, 0);
        },
      );

      test(
        'anonymous-bootstrap marker corrupt (String): startup '
        'resolveAndReconcile performs ZERO destructive work — never calls '
        'completeAnonymousBootstrap / ensureAnonymousSession',
        () async {
          final storage = LocalStorage.ephemeral({
            AccountDeletionService.pendingAnonymousBootstrapKey: 'true',
          });
          final auth = _CountingAuth();
          final server = _CountingServerDelete();
          final deletion = AccountDeletionService(
            auth: auth,
            storage: storage,
            secureStorage: InMemorySecureStorage(),
            deleteServerData: server.call,
          );

          await AccountDeletionPendingState.resolveAndReconcile(
            storage,
            deletion,
          );

          expect(AccountDeletionPendingState.isIntegrityRecovery, isTrue);
          expect(auth.ensureAnonymousSessionCalls, 0);
          expect(auth.deleteAccountCalls, 0);
          expect(server.calls, 0);
        },
      );

      test(
        'anonymous-bootstrap marker corrupt (a double, a real durable-'
        'storage type — never a synthetic in-memory-only case): startup '
        'resolveAndReconcile performs ZERO destructive work',
        () async {
          SharedPreferences.setMockInitialValues({
            AccountDeletionService.pendingAnonymousBootstrapKey: 9.5,
          });
          final storage = LocalStorage(await SharedPreferences.getInstance());
          final auth = _CountingAuth();
          final server = _CountingServerDelete();
          final deletion = AccountDeletionService(
            auth: auth,
            storage: storage,
            secureStorage: InMemorySecureStorage(),
            deleteServerData: server.call,
          );

          await AccountDeletionPendingState.resolveAndReconcile(
            storage,
            deletion,
          );

          expect(AccountDeletionPendingState.isIntegrityRecovery, isTrue);
          expect(auth.ensureAnonymousSessionCalls, 0);
          expect(auth.deleteAccountCalls, 0);
          expect(server.calls, 0);
        },
      );

      test(
        'DIRECT retryPendingIdentityCleanup call with a corrupt marker '
        'refuses with a typed "deletion_state_corrupt" failure and performs '
        'ZERO destructive work — defense in depth even if a caller bypasses '
        'the startup gate entirely',
        () async {
          final storage = LocalStorage.ephemeral({
            AccountDeletionService.pendingIdentityCleanupKey: 'true',
          });
          final auth = _CountingAuth();
          final server = _CountingServerDelete();
          final deletion = AccountDeletionService(
            auth: auth,
            storage: storage,
            secureStorage: InMemorySecureStorage(),
            deleteServerData: server.call,
          );

          final result = await deletion.retryPendingIdentityCleanup();

          expect(result.isFailure, isTrue);
          expect(result.errorOrNull?.message, 'deletion_state_corrupt');
          expect(auth.deleteAccountCalls, 0);
          expect(auth.ensureAnonymousSessionCalls, 0);
          expect(server.calls, 0);
        },
      );

      test(
        'DIRECT retryPendingIdentityCleanup call with a corrupt '
        'anonymous-bootstrap marker also refuses without destructive work',
        () async {
          final storage = LocalStorage.ephemeral({
            AccountDeletionService.pendingAnonymousBootstrapKey: 99,
          });
          final auth = _CountingAuth();
          final server = _CountingServerDelete();
          final deletion = AccountDeletionService(
            auth: auth,
            storage: storage,
            secureStorage: InMemorySecureStorage(),
            deleteServerData: server.call,
          );

          final result = await deletion.retryPendingIdentityCleanup();

          expect(result.isFailure, isTrue);
          expect(result.errorOrNull?.message, 'deletion_state_corrupt');
          expect(auth.ensureAnonymousSessionCalls, 0);
          expect(auth.deleteAccountCalls, 0);
          expect(server.calls, 0);
        },
      );
    },
  );

  group(
    'finalizer: replacement identity must be positively proven anonymous '
    'before the gate is ever cleared',
    () {
      test(
        'ensureAnonymousSession "succeeding" while reusing an existing '
        'LINKED (non-anonymous) current identity must NOT clear the gate — '
        'stays finalizing, returns failure, never removes the pending marker',
        () async {
          SharedPreferences.setMockInitialValues({
            AccountDeletionFinalizer.anonymousBootstrapKey: true,
          });
          final storage = LocalStorage(await SharedPreferences.getInstance());
          final auth = _LinkedIdentityReuseAuth();
          AccountDeletionPendingState.markFinalizing();

          final result = await AccountDeletionFinalizer.completeAnonymousBootstrap(
            auth: auth,
            storage: storage,
            identityCleanupKey:
                AccountDeletionService.pendingIdentityCleanupKey,
          );

          expect(result.isFailure, isTrue);
          expect(AccountDeletionPendingState.isFinalizing, isTrue);
          expect(AccountDeletionPendingState.isClear, isFalse);
          expect(
            storage.getBool(AccountDeletionFinalizer.anonymousBootstrapKey),
            isTrue,
            reason: 'must not remove the pending marker for an unproven '
                'identity',
          );
        },
      );

      test(
        'ensureAnonymousSession succeeding with a genuinely anonymous '
        'current identity clears the gate normally',
        () async {
          SharedPreferences.setMockInitialValues({
            AccountDeletionFinalizer.anonymousBootstrapKey: true,
            AccountDeletionTarget.targetUidKey: 'deleted-owner-A',
          });
          final storage = LocalStorage(await SharedPreferences.getInstance());
          final auth = MockAuthService(
            sessions: InMemorySessionManager(_NoopTokens()),
          );
          // No pre-existing identity — bootstrap must CREATE the replacement.
          AccountDeletionPendingState.markFinalizing();

          final result = await AccountDeletionFinalizer.completeAnonymousBootstrap(
            auth: auth,
            storage: storage,
            identityCleanupKey:
                AccountDeletionService.pendingIdentityCleanupKey,
          );

          expect(result.isSuccess, isTrue);
          expect(AccountDeletionPendingState.isClear, isTrue);
          expect(auth.hasCurrentIdentity, isTrue);
          expect(auth.isCurrentUserAnonymous, isTrue);
        },
      );
    },
  );

  group('canonical post-gate owner startup coordinator', () {
    ProviderContainer buildContainer(
      LocalStorage storage, {
      AuthService? auth,
    }) {
      return ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          secureStorageProvider.overrideWithValue(InMemorySecureStorage()),
          premiumRepositoryProvider.overrideWithValue(
            _CountingPremium(storage),
          ),
          authServiceProvider.overrideWithValue(auth ?? MockAuthService()),
        ],
      );
    }

    /// A real (non-Mock) current identity — AnonymousAuthBootstrap.ensure
    /// explicitly refuses to drive MockAuthService, so any test that needs
    /// runIfClear to observe hasCurrentIdentity == true after the attempt
    /// must pre-establish a real session first.
    Future<MockAuthService> buildAuthWithSession() async {
      final auth = MockAuthService(
        sessions: InMemorySessionManager(_NoopTokens()),
      );
      await auth.signInAnonymously();
      return auth;
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
      'runIfClear runs the full pipeline and reports ownerIdentityEstablished '
      'when an owner identity already exists — the same pipeline a normal '
      'cold start and a successful storage recovery both resume',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = LocalStorage(await SharedPreferences.getInstance());
        final auth = await buildAuthWithSession();
        final container = buildContainer(storage, auth: auth);
        addTearDown(container.dispose);
        AccountDeletionPendingState.markClear();

        final outcome = await AccountDeletionOwnerBootstrap.runIfClear(
          container,
        );

        expect(outcome, OwnerStartupOutcome.ownerIdentityEstablished);
        final premium =
            container.read(premiumRepositoryProvider) as _CountingPremium;
        expect(premium.warmCount, 1);
      },
    );

    test(
      'P0 FIX: runIfClear reports ownerIdentityUnavailable — never a '
      'lying "completed" — when no owner identity exists after the attempt '
      '(bootstrap unavailable/failed)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = LocalStorage(await SharedPreferences.getInstance());
        // Bare MockAuthService has no session, and AnonymousAuthBootstrap
        // explicitly refuses to drive MockAuthService — simulates a real
        // bootstrap that could not establish any identity.
        final container = buildContainer(storage, auth: MockAuthService());
        addTearDown(container.dispose);
        AccountDeletionPendingState.markClear();

        final outcome = await AccountDeletionOwnerBootstrap.runIfClear(
          container,
        );

        expect(outcome, OwnerStartupOutcome.ownerIdentityUnavailable);
      },
    );

    test(
      'concurrent runIfClear calls single-flight — Premium is warmed once, '
      'not twice, for two overlapping callers (main + storage-recovery '
      'race), and both callers observe the SAME real outcome',
      () async {
        SharedPreferences.setMockInitialValues({});
        final storage = LocalStorage(await SharedPreferences.getInstance());
        final auth = await buildAuthWithSession();
        final container = buildContainer(storage, auth: auth);
        addTearDown(container.dispose);
        AccountDeletionPendingState.markClear();

        final results = await Future.wait([
          AccountDeletionOwnerBootstrap.runIfClear(container),
          AccountDeletionOwnerBootstrap.runIfClear(container),
        ]);

        expect(
          results,
          everyElement(OwnerStartupOutcome.ownerIdentityEstablished),
        );
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

  group('P0-5: storage recovery must not fabricate auth success', () {
    testWidgets(
        'durable storage resolves clear but no owner identity is '
        'available → stays in secure recovery UX, never routes Home, '
        'never fabricates auth success', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      AccountDeletionPendingState.markStorageUnavailable();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            localStorageProvider.overrideWithValue(storage),
            secureStorageProvider.overrideWithValue(InMemorySecureStorage()),
            premiumRepositoryProvider.overrideWithValue(
              MockPremiumRepository(
                storage,
                secureStorage: InMemorySecureStorage(),
              ),
            ),
            // Bare MockAuthService: no session, and AnonymousAuthBootstrap
            // refuses to drive MockAuthService — simulates owner-identity
            // bootstrap being genuinely unavailable even though storage
            // itself resolved clear.
            authServiceProvider.overrideWithValue(MockAuthService()),
          ],
          child: const MaterialApp(home: SecureStartupRecoveryScreen()),
        ),
      );

      await tester.tap(find.text(PrivacyControlCopy.storageRecoveryRetry));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(SecureStartupRecoveryScreen), findsOneWidget);
      expect(find.byType(OraclyAppShell), findsNothing);
      expect(find.byType(AccountDeletionPendingScreen), findsNothing);
    });

    // The counter-case (identity already established → proceeds past
    // recovery) is proven at the unit level instead of as a widget test:
    // "runIfClear runs the full pipeline and reports ownerIdentityEstablished
    // when an owner identity already exists" above covers the outcome this
    // router branches on. A full widget-level pump of that path additionally
    // exercises real push-installation platform channels
    // (installReadingPushIfClear) with no plugin mocking, which hangs
    // indefinitely in this test binding rather than failing fast — pumping
    // fake frame time does not advance real platform-channel IO. Existing
    // SplashDestination tests already cover "clear phase renders
    // Home/Onboarding" independently of the owner-bootstrap pipeline.
  });

  group(
    'P1 — storage recovery must resume deferred splash work '
    '(best-effort, non-blocking, single-flight, shared with normal splash)',
    () {
      ProviderContainer buildWarmupContainer(
        LocalStorage storage, {
        required _CountingCoordinator coordinator,
        required List<int> gemTouches,
      }) {
        return ProviderContainer(
          overrides: [
            localStorageProvider.overrideWithValue(storage),
            paidAiOperationCoordinatorProvider.overrideWithValue(coordinator),
            gemWalletProvider.overrideWith((ref) {
              gemTouches[0]++;
              return GemWalletController(
                GemWalletService(GemWalletStore(storage)),
              );
            }),
          ],
        );
      }

      test('storageUnavailable: deferred warmup count 0', () async {
        SharedPreferences.setMockInitialValues({});
        final storage = LocalStorage(await SharedPreferences.getInstance());
        final coordinator = _CountingCoordinator(storage);
        final gemTouches = [0];
        final container = buildWarmupContainer(
          storage,
          coordinator: coordinator,
          gemTouches: gemTouches,
        );
        addTearDown(container.dispose);
        AccountDeletionPendingState.markStorageUnavailable();

        final outcome = await scheduleDeferredWarmupIfClear(container);

        expect(outcome, DeferredWarmupOutcome.skippedNotClear);
        expect(coordinator.reconcileCount, 0);
        expect(gemTouches[0], 0);
      });

      test('blocked: deferred owner warmup count 0', () async {
        SharedPreferences.setMockInitialValues({});
        final storage = LocalStorage(await SharedPreferences.getInstance());
        final coordinator = _CountingCoordinator(storage);
        final gemTouches = [0];
        final container = buildWarmupContainer(
          storage,
          coordinator: coordinator,
          gemTouches: gemTouches,
        );
        addTearDown(container.dispose);
        AccountDeletionPendingState.markBlocked();

        final outcome = await scheduleDeferredWarmupIfClear(container);

        expect(outcome, DeferredWarmupOutcome.skippedNotClear);
        expect(coordinator.reconcileCount, 0);
        expect(gemTouches[0], 0);
      });

      test('finalizing: deferred owner warmup count 0', () async {
        SharedPreferences.setMockInitialValues({});
        final storage = LocalStorage(await SharedPreferences.getInstance());
        final coordinator = _CountingCoordinator(storage);
        final gemTouches = [0];
        final container = buildWarmupContainer(
          storage,
          coordinator: coordinator,
          gemTouches: gemTouches,
        );
        addTearDown(container.dispose);
        AccountDeletionPendingState.markFinalizing();

        final outcome = await scheduleDeferredWarmupIfClear(container);

        expect(outcome, DeferredWarmupOutcome.skippedNotClear);
        expect(coordinator.reconcileCount, 0);
        expect(gemTouches[0], 0);
      });

      test('integrityRecovery: deferred owner warmup count 0', () async {
        SharedPreferences.setMockInitialValues({});
        final storage = LocalStorage(await SharedPreferences.getInstance());
        final coordinator = _CountingCoordinator(storage);
        final gemTouches = [0];
        final container = buildWarmupContainer(
          storage,
          coordinator: coordinator,
          gemTouches: gemTouches,
        );
        addTearDown(container.dispose);
        AccountDeletionPendingState.markIntegrityRecovery();

        final outcome = await scheduleDeferredWarmupIfClear(container);

        expect(outcome, DeferredWarmupOutcome.skippedNotClear);
        expect(coordinator.reconcileCount, 0);
        expect(gemTouches[0], 0);
      });

      test(
        'clear: required + best-effort deferred warmup scheduled once — '
        'paid-op reconcile runs, gem wallet is touched',
        () async {
          SharedPreferences.setMockInitialValues({});
          final storage = LocalStorage(await SharedPreferences.getInstance());
          final coordinator = _CountingCoordinator(storage);
          final gemTouches = [0];
          final container = buildWarmupContainer(
            storage,
            coordinator: coordinator,
            gemTouches: gemTouches,
          );
          addTearDown(container.dispose);
          AccountDeletionPendingState.markClear();

          final outcome = await scheduleDeferredWarmupIfClear(container);

          expect(outcome, DeferredWarmupOutcome.completed);
          expect(coordinator.reconcileCount, 1);
          expect(gemTouches[0], 1);
        },
      );

      test(
        'concurrent normal-splash + storage-recovery invocation single-'
        'flights — paid-op reconcile runs once, not twice, for two '
        'overlapping callers',
        () async {
          SharedPreferences.setMockInitialValues({});
          final storage = LocalStorage(await SharedPreferences.getInstance());
          final coordinator = _CountingCoordinator(storage);
          final gemTouches = [0];
          final container = buildWarmupContainer(
            storage,
            coordinator: coordinator,
            gemTouches: gemTouches,
          );
          addTearDown(container.dispose);
          AccountDeletionPendingState.markClear();

          final results = await Future.wait([
            scheduleDeferredWarmupIfClear(container),
            scheduleDeferredWarmupIfClear(container),
          ]);

          expect(results, everyElement(DeferredWarmupOutcome.completed));
          expect(
            coordinator.reconcileCount,
            1,
            reason: 'single-flight must prevent a second concurrent deferred '
                'warmup from reconciling paid ops again',
          );
        },
      );
    },
  );
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

/// Counts every destructive call — proves a corrupt marker performs ZERO
/// of them. A LINKED (non-anonymous) identity is simulated by default so a
/// bug that skipped the corrupt-marker guard would be caught reaching for
/// reauth/delete, not silently short-circuited by an anonymous fast path.
class _CountingAuth implements AuthService {
  int deleteAccountCalls = 0;
  int ensureAnonymousSessionCalls = 0;
  int reauthenticateCalls = 0;

  @override
  bool get isConfigured => true;
  @override
  bool get isCurrentUserAnonymous => false;
  @override
  bool get hasCurrentIdentity => true;

  @override
  String? get currentUserId => null;
  @override
  List<AccountReauthMethod> get currentReauthMethods => const [];
  @override
  String? get currentUserEmail => null;

  @override
  Future<ApiResult<AuthSession>> signInAnonymously() async =>
      ApiFailure(NetworkException.unauthorized());
  @override
  Future<ApiResult<AuthSession>> signInWithGoogle(
    OAuthCredentials credentials,
  ) async =>
      ApiFailure(NetworkException.unauthorized());
  @override
  Future<ApiResult<AuthSession>> signInWithApple(
    OAuthCredentials credentials,
  ) async =>
      ApiFailure(NetworkException.unauthorized());
  @override
  Future<ApiResult<AuthSession>> signInWithEmail(
    EmailCredentials credentials,
  ) async =>
      ApiFailure(NetworkException.unauthorized());
  @override
  Future<ApiResult<AuthSession>> createGuestSession() async =>
      ApiFailure(NetworkException.unauthorized());
  @override
  Future<ApiResult<AuthSession>> refreshSession() async =>
      ApiFailure(NetworkException.unauthorized());

  @override
  Future<ApiResult<AuthSession>> ensureAnonymousSession() async {
    ensureAnonymousSessionCalls++;
    return ApiFailure(NetworkException.unauthorized());
  }

  @override
  Future<ApiResult<bool>> signOut() async => const ApiSuccess(true);

  @override
  Future<ApiResult<bool>> deleteAccount() async {
    deleteAccountCalls++;
    return const ApiSuccess(true);
  }

  @override
  Future<ApiResult<bool>> reauthenticate(
    AccountReauthCredentials credentials,
  ) async {
    reauthenticateCalls++;
    return const ApiSuccess(true);
  }
}

/// Counts calls to the server-delete callback — the FIRST destructive step
/// [AccountDeletionService.deleteAccountAndWipeLocalData] would take.
class _CountingServerDelete {
  int calls = 0;
  Future<bool> call(String expectedTargetUid) async {
    calls++;
    return true;
  }
}

/// Simulates the exact FirebaseAuthService bug: ensureAnonymousSession
/// reports success by reusing whatever current user already exists,
/// without itself checking that user is anonymous.
class _LinkedIdentityReuseAuth implements AuthService {
  @override
  bool get isConfigured => true;
  @override
  bool get isCurrentUserAnonymous => false;
  @override
  bool get hasCurrentIdentity => true;

  @override
  String? get currentUserId => null;
  @override
  List<AccountReauthMethod> get currentReauthMethods =>
      const [AccountReauthMethod.google];
  @override
  String? get currentUserEmail => null;

  @override
  Future<ApiResult<AuthSession>> signInAnonymously() async =>
      ApiFailure(NetworkException.unauthorized());
  @override
  Future<ApiResult<AuthSession>> signInWithGoogle(
    OAuthCredentials credentials,
  ) async =>
      ApiFailure(NetworkException.unauthorized());
  @override
  Future<ApiResult<AuthSession>> signInWithApple(
    OAuthCredentials credentials,
  ) async =>
      ApiFailure(NetworkException.unauthorized());
  @override
  Future<ApiResult<AuthSession>> signInWithEmail(
    EmailCredentials credentials,
  ) async =>
      ApiFailure(NetworkException.unauthorized());
  @override
  Future<ApiResult<AuthSession>> createGuestSession() async =>
      ApiFailure(NetworkException.unauthorized());
  @override
  Future<ApiResult<AuthSession>> refreshSession() async =>
      ApiFailure(NetworkException.unauthorized());

  /// "Succeeds" — but by reusing the still-linked current identity, exactly
  /// like the real bug: it never establishes a fresh anonymous session.
  @override
  Future<ApiResult<AuthSession>> ensureAnonymousSession() async {
    return ApiSuccess(
      AuthSession(
        userId: 'linked-user-still-here',
        provider: AuthProviderKind.google,
        accessToken: 'tok',
        refreshToken: 'refresh',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      ),
    );
  }

  @override
  Future<ApiResult<bool>> signOut() async => const ApiSuccess(true);
  @override
  Future<ApiResult<bool>> deleteAccount() async => const ApiSuccess(true);
  @override
  Future<ApiResult<bool>> reauthenticate(
    AccountReauthCredentials credentials,
  ) async =>
      const ApiSuccess(true);
}

/// Counts [PaidAiOperationCoordinator.reconcile] calls — proves the P1
/// deferred-warmup coordinator schedules it exactly once (never zero for a
/// clear gate, never twice for concurrent callers).
class _CountingCoordinator extends PaidAiOperationCoordinator {
  _CountingCoordinator(LocalStorage storage)
      : super(
          wallet: GemWalletService(GemWalletStore(storage)),
          storage: storage,
        );

  int reconcileCount = 0;

  @override
  Future<int> reconcile() async {
    reconcileCount++;
    return super.reconcile();
  }
}
