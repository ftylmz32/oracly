/// Account deletion: remote-first, honest failures, local wipe only after success.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/account_deletion_finalizer.dart';
import 'package:oracly_new/core/auth/account_deletion_pending_state.dart';
import 'package:oracly_new/core/auth/account_deletion_service.dart';
import 'package:oracly_new/core/auth/auth_copy.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_errors.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_gateway.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_service.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_user.dart';
import 'package:oracly_new/core/auth/firebase/firebase_id_token_manager.dart';
import 'package:oracly_new/core/auth/models/account_reauth_method.dart';
import 'package:oracly_new/core/auth/models/auth_credentials.dart';
import 'package:oracly_new/core/auth/session_manager.dart';
import 'package:oracly_new/core/auth/token_manager.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/intelligence/data/personal_memory_store.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/favorite_moments/data/local_favorite_moments_repository.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/premium/models/premium_purchase_credentials.dart';
import 'package:oracly_new/features/tarot/data/datasources/tarot_local_datasource.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _idToken = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.e30.sig';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late InMemorySecureStorage secure;
  late MockPremiumRepository premiumRepo;
  late _DeletionGateway gateway;
  late FirebaseAuthService auth;
  late AccountDeletionService deletion;
  late _MemTokens tokens;
  late InMemorySessionManager sessions;

  setUp(() async {
    AccountDeletionPendingState.markClear();
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    secure = InMemorySecureStorage();
    premiumRepo = MockPremiumRepository(storage, secureStorage: secure);
    gateway = _DeletionGateway();
    tokens = _MemTokens();
    sessions = InMemorySessionManager(
      FirebaseIdTokenManager(gateway, fallback: tokens),
    );
    auth = FirebaseAuthService(
      gateway: gateway,
      tokens: tokens,
      sessions: sessions,
      isolation: UserLocalDataIsolation(storage, secureStorage: secure),
    );
    deletion = AccountDeletionService(
      auth: auth,
      storage: storage,
      secureStorage: secure,
      deleteServerData: () async => true,
    );
  });

  tearDown(() {
    AccountDeletionPendingState.markClear();
    auth.dispose();
  });

  Future<void> seedUserBound() async {
    await storage.setStringList('or_reading_history', const ['r1']);
    await storage.setStringList(TarotLocalDataSource.historyKey, const ['t1']);
    await storage.setString(LocalFavoriteMomentsRepository.key, 'fav');
    await storage.setString(PersonalMemoryStore.key, 'mem');
    await storage.setString('user_name', 'Ada');
    await storage.setString('settings_language', 'en');
    await storage.setBool('onboarding_completed', true);
    // Reading-count idempotency ledger — account-scoped state a deletion
    // must wipe exactly like the rest of this owner's history/profile.
    await storage.setInt('profile_readings', 7);
    await storage.setStringList(
      MockUserRepository.readingLedgerIdsKey,
      const ['del-r1', 'del-r2'],
    );
    await storage.setInt(MockUserRepository.legacyBaselineKey, 5);
    final premium = premiumRepo;
    await premium.activatePlan(PremiumPlanKind.yearly, authoritative: true);
    await premium.savePurchaseCredentials(
      const PremiumPurchaseCredentials(
        platform: 'android',
        productId: 'oracly_premium_yearly',
        purchaseToken: 'tok-del',
        transactionId: 'txn-del',
      ),
    );
  }

  Future<void> expectUserBoundCleared() async {
    expect(storage.getStringList('or_reading_history'), isEmpty);
    expect(storage.getStringList(TarotLocalDataSource.historyKey), isEmpty);
    expect(storage.getString(LocalFavoriteMomentsRepository.key), isNull);
    expect(storage.getString(PersonalMemoryStore.key), isNull);
    expect(storage.getString('user_name'), isNull);
    expect(await premiumRepo.readPurchaseCredentials(), isNull);
    expect(premiumRepo.isActiveNow, isFalse);
    expect(storage.getInt('profile_readings'), isNull);
    expect(
      storage.getStringList(MockUserRepository.readingLedgerIdsKey),
      isNull,
    );
    expect(storage.getInt(MockUserRepository.legacyBaselineKey), isNull);
  }

  test(
    'anonymous deletion success wipes local and bootstraps fresh session',
    () async {
      await seedUserBound();
      await auth.signInAnonymously();
      expect(gateway.currentUser?.isAnonymous, isTrue);
      final beforeAnon = gateway.anonSerial;

      final result = await deletion.deleteAccountAndWipeLocalData();

      expect(result.isSuccess, isTrue);
      await expectUserBoundCleared();
      expect(storage.getString('settings_language'), 'en');
      expect(storage.getBool('onboarding_completed'), isTrue);
      expect(sessions.currentSession, isNotNull);
      expect(gateway.currentUser, isNotNull);
      expect(gateway.deleteCalls, 1);
      expect(AccountDeletionPendingState.isClear, isTrue);
      expect(deletion.hasPendingAnonymousBootstrap, isFalse);
      // Exactly one replacement anonymous identity after the deleted one.
      expect(gateway.anonSerial, beforeAnon + 1);
    },
  );

  test(
    'successful deletion cannot resurrect the deleted owner\'s reading '
    'count — a FRESH MockUserRepository over the same storage reports a '
    'genuine totalReadings == 0, not the deleted owner\'s baseline',
    () async {
      await seedUserBound();
      await auth.signInAnonymously();

      final result = await deletion.deleteAccountAndWipeLocalData();
      expect(result.isSuccess, isTrue);
      await expectUserBoundCleared();

      // A brand-new repository instance — proves the zero comes from
      // durably-cleared storage, not a value cached on the old instance.
      final freshUsers = MockUserRepository(storage);
      final freshProfile = await freshUsers.getProfile();
      expect(freshProfile.totalReadings, 0);
      expect(freshProfile.unlockedAchievementKeys, isEmpty);

      // Migration must activate fresh for the new anonymous owner too —
      // with no legacy ids to reconcile, one genuinely new reading must
      // contribute exactly +1, not resume from the deleted owner's 7.
      await freshUsers.ensureReadingCompletionMigration(const []);
      await freshUsers.recordReadingCompletion('post-deletion-r1');
      expect((await freshUsers.getProfile()).totalReadings, 1);
    },
  );

  test(
    'local wipe failure AFTER the identity is genuinely deleted stays '
    'finalizing — residual ledger is never attached to a "clear" '
    'anonymous session; retry after storage recovers completes cleanly '
    'with no second destructive identity delete',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final failingStorage = _KeyFailingStorage(
        prefs,
        failingKeys: {MockUserRepository.readingLedgerIdsKey},
      );
      final failingSecure = InMemorySecureStorage();
      final failingGateway = _DeletionGateway();
      final failingSessions = InMemorySessionManager(
        FirebaseIdTokenManager(failingGateway, fallback: _MemTokens()),
      );
      final failingAuth = FirebaseAuthService(
        gateway: failingGateway,
        tokens: _MemTokens(),
        sessions: failingSessions,
        isolation: UserLocalDataIsolation(
          failingStorage,
          secureStorage: failingSecure,
        ),
      );
      final failingDeletion = AccountDeletionService(
        auth: failingAuth,
        storage: failingStorage,
        secureStorage: failingSecure,
        deleteServerData: () async => true,
      );

      await failingAuth.signInAnonymously();
      await failingStorage.setStringList('or_reading_history', const ['r1']);
      final usersOnFailingStorage = MockUserRepository(failingStorage);
      await usersOnFailingStorage.ensureReadingCompletionMigration(const []);
      await usersOnFailingStorage.recordReadingCompletion('pre-deletion-r1');
      expect((await usersOnFailingStorage.getProfile()).totalReadings, 1);

      // Server delete succeeds, identity delete succeeds, local wipe
      // starts, readingLedgerIdsKey's own removal fails.
      final result = await failingDeletion.deleteAccountAndWipeLocalData();

      expect(
        result.isSuccess,
        isFalse,
        reason: 'the local wipe did not fully complete',
      );
      expect(failingGateway.deleteCalls, 1);
      expect(
        AccountDeletionPendingState.isFinalizing,
        isTrue,
        reason: 'a real deletion is known to exist — stay hidden from the '
            'app, fail-closed, never clear or blocked',
      );
      expect(failingDeletion.hasPendingLocalWipe, isTrue);
      expect(
        failingDeletion.hasPendingIdentityCleanup,
        isFalse,
        reason: 'the identity really is gone — that concern is resolved; '
            'a retry must never re-attempt deleteAccount on it',
      );
      expect(failingDeletion.hasPendingAnonymousBootstrap, isFalse);
      expect(
        failingStorage.getStringList(MockUserRepository.readingLedgerIdsKey),
        isNotNull,
        reason: 'the residual ledger must still be there — never silently '
            'attached to a "clear" anonymous session',
      );

      // Restart: recreate storage/service state, make storage healthy,
      // retry finalization.
      final healthyStorage = LocalStorage(prefs);
      final healthyDeletion = AccountDeletionService(
        auth: failingAuth,
        storage: healthyStorage,
        secureStorage: failingSecure,
        deleteServerData: () async => true,
      );

      final retryResult = await healthyDeletion.retryPendingIdentityCleanup();

      expect(retryResult.isSuccess, isTrue);
      expect(
        failingGateway.deleteCalls,
        1,
        reason: 'no second destructive delete of an already-deleted '
            'identity',
      );
      expect(AccountDeletionPendingState.isClear, isTrue);
      expect(
        healthyStorage.getStringList(MockUserRepository.readingLedgerIdsKey),
        isNull,
      );
      expect(
        healthyStorage.getInt(MockUserRepository.legacyBaselineKey),
        isNull,
      );
      final freshProfileAfterRetry =
          await MockUserRepository(healthyStorage).getProfile();
      expect(freshProfileAfterRetry.totalReadings, 0);
      expect(healthyDeletion.hasPendingLocalWipe, isFalse);
      expect(healthyDeletion.hasPendingAnonymousBootstrap, isFalse);
      expect(healthyDeletion.hasPendingIdentityCleanup, isFalse);
    },
  );

  test(
    'P0-4: if the durable local-wipe marker itself fails to write, this '
    'fails closed WITHOUT ever starting the wipe — residue is completely '
    'untouched, and the gate stays finalizing, never clear',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final failingStorage = _BoolWriteFailingStorage(
        prefs,
        failingKey: AccountDeletionFinalizer.localWipePendingKey,
      );
      await failingStorage.setStringList(
        'or_reading_history',
        const ['old owner reading'],
      );
      await MockUserRepository(failingStorage).ensureReadingCompletionMigration(
        const [],
      );
      await MockUserRepository(failingStorage).recordReadingCompletion(
        'pre-crash-r1',
      );

      final result = await AccountDeletionFinalizer.finishAfterIdentityDeleted(
        auth: auth,
        storage: failingStorage,
        secureStorage: InMemorySecureStorage(),
        identityCleanupKey: 'irrelevant_identity_key',
      );

      expect(result.isFailure, isTrue);
      expect(
        failingStorage.getStringList('or_reading_history'),
        isNotEmpty,
        reason: 'the wipe must never have started at all',
      );
      expect(
        failingStorage.getStringList(MockUserRepository.readingLedgerIdsKey),
        isNotNull,
        reason: 'residue is completely untouched, not partially wiped',
      );
      expect(AccountDeletionPendingState.isFinalizing, isTrue);
    },
  );

  test(
    'P0-4: if establishing the anonymous-bootstrap marker itself fails '
    'AFTER a successful wipe, the local-wipe marker is NOT prematurely '
    'retired — no durable window where every finalization marker is '
    'absent while finalization is not actually done',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final failingStorage = _BoolWriteFailingStorage(
        prefs,
        failingKey: AccountDeletionFinalizer.anonymousBootstrapKey,
      );

      final result = await AccountDeletionFinalizer.finishAfterIdentityDeleted(
        auth: auth,
        storage: failingStorage,
        secureStorage: InMemorySecureStorage(),
        identityCleanupKey: 'irrelevant_identity_key',
      );

      expect(result.isFailure, isTrue);
      expect(
        failingStorage.getBool(AccountDeletionFinalizer.localWipePendingKey),
        isTrue,
        reason: 'the handoff to anonymousBootstrapKey never durably '
            'succeeded, so localWipePendingKey must not have been '
            'retired — some finalization marker is ALWAYS present here',
      );
      expect(AccountDeletionPendingState.isFinalizing, isTrue);
    },
  );

  test(
    'authenticated deletion success clears premium credentials and history',
    () async {
      await seedUserBound();
      final signedIn = await auth.signInWithEmail(
        const EmailCredentials(email: 'a@b.c', password: 'x'),
      );
      expect(signedIn.isSuccess, isTrue);
      expect(gateway.currentUser?.isAnonymous, isFalse);

      final result = await deletion.deleteAccountAndWipeLocalData(
        reauth: const AccountReauthCredentials.email(
          EmailCredentials(email: 'a@b.c', password: 'x'),
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(gateway.reauthCalls, 1);
      await expectUserBoundCleared();
      expect(gateway.deleteCalls, 1);
      expect(gateway.currentUser?.isAnonymous, isTrue);
    },
  );

  test('Firebase deletion failure does not wipe or claim success', () async {
    await seedUserBound();
    await auth.signInAnonymously();
    gateway.deleteError = 'network-request-failed';

    final result = await deletion.deleteAccountAndWipeLocalData();

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull?.message, isNot(AuthCopy.signedOut));
    expect(storage.getStringList('or_reading_history'), isNotEmpty);
    expect(storage.getString('user_name'), 'Ada');
    expect(await premiumRepo.readPurchaseCredentials(), isNotNull);
    expect(gateway.currentUser, isNotNull);
    expect(sessions.currentSession, isNotNull);
    // Remote-first contract: deletion is NOT complete, so the reading
    // ledger must remain exactly as it was — never wiped ahead of a real
    // success.
    expect(storage.getInt('profile_readings'), 7);
    expect(
      storage.getStringList(MockUserRepository.readingLedgerIdsKey),
      ['del-r1', 'del-r2'],
    );
    expect(storage.getInt(MockUserRepository.legacyBaselineKey), 5);
  });

  test('requires-recent-login fails honestly without wipe or logout', () async {
    await seedUserBound();
    await auth.signInWithEmail(
      const EmailCredentials(email: 'a@b.c', password: 'x'),
    );
    gateway.deleteError = 'requires-recent-login';

    final result = await deletion.deleteAccountAndWipeLocalData(
      reauth: const AccountReauthCredentials.email(
        EmailCredentials(email: 'a@b.c', password: 'x'),
      ),
    );

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull?.message, AuthCopy.requiresRecentLogin);
    expect(storage.getStringList('or_reading_history'), isNotEmpty);
    expect(premiumRepo.isActiveNow, isTrue);
    expect(gateway.currentUser?.email, 'a@b.c');
    expect(sessions.currentSession, isNotNull);
    // Reauth failed BEFORE any destructive step — the ledger must be
    // completely untouched, not partially wiped.
    expect(storage.getInt('profile_readings'), 7);
    expect(
      storage.getStringList(MockUserRepository.readingLedgerIdsKey),
      ['del-r1', 'del-r2'],
    );
    expect(storage.getInt(MockUserRepository.legacyBaselineKey), 5);
  });

  test('no current user fails without wipe', () async {
    await seedUserBound();
    expect(gateway.currentUser, isNull);

    final result = await deletion.deleteAccountAndWipeLocalData();

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull?.message, AuthCopy.noCurrentUser);
    expect(storage.getString('user_name'), 'Ada');
    expect(gateway.deleteCalls, 0);
  });

  test(
    'deleteAccount alone never pretends logout is deletion success',
    () async {
      await auth.signInAnonymously();
      gateway.deleteError = 'requires-recent-login';

      final failed = await auth.deleteAccount();
      expect(failed.isFailure, isTrue);
      expect(gateway.currentUser, isNotNull);

      gateway.deleteError = null;
      final ok = await auth.deleteAccount();
      expect(ok.isSuccess, isTrue);
      expect(gateway.currentUser, isNull);
      expect(sessions.currentSession, isNull);
    },
  );

  test(
    'requires-recent-login persists a pending-identity-cleanup marker '
    '(server data was already deleted; the identity was not)',
    () async {
      await seedUserBound();
      await auth.signInWithEmail(
        const EmailCredentials(email: 'a@b.c', password: 'x'),
      );
      gateway.deleteError = 'requires-recent-login';
      expect(deletion.hasPendingIdentityCleanup, isFalse);

      final result = await deletion.deleteAccountAndWipeLocalData(
        reauth: const AccountReauthCredentials.email(
          EmailCredentials(email: 'a@b.c', password: 'x'),
        ),
      );

      expect(result.isFailure, isTrue);
      expect(deletion.hasPendingIdentityCleanup, isTrue);
      // Still fail-safe: no local wipe, no logout, while pending.
      expect(storage.getString('user_name'), 'Ada');
      expect(gateway.currentUser?.email, 'a@b.c');
    },
  );

  test(
    'post-server identity network failure marks pending — wipe stays zero',
    () async {
      await seedUserBound();
      await auth.signInAnonymously();
      gateway.deleteError = 'network-request-failed';

      final result = await deletion.deleteAccountAndWipeLocalData();

      expect(result.isFailure, isTrue);
      expect(deletion.hasPendingIdentityCleanup, isTrue);
      expect(AccountDeletionPendingState.isBlocked, isTrue);
      expect(storage.getString('user_name'), 'Ada');
      expect(gateway.currentUser, isNotNull);
    },
  );

  test(
    'post-server Firebase internal failure marks pending',
    () async {
      await seedUserBound();
      await auth.signInWithEmail(
        const EmailCredentials(email: 'a@b.c', password: 'x'),
      );
      gateway.deleteError = 'internal-error';

      final result = await deletion.deleteAccountAndWipeLocalData(
        reauth: const AccountReauthCredentials.email(
          EmailCredentials(email: 'a@b.c', password: 'x'),
        ),
      );

      expect(result.isFailure, isTrue);
      expect(deletion.hasPendingIdentityCleanup, isTrue);
      expect(AccountDeletionPendingState.isBlocked, isTrue);
      expect(storage.getString('user_name'), 'Ada');
    },
  );

  test(
    'post-server identity already absent finishes wipe without pending loop',
    () async {
      await seedUserBound();
      await auth.signInAnonymously();
      gateway.deleteError = 'no-current-user';
      gateway.clearUserBeforeThrowing = true;

      final result = await deletion.deleteAccountAndWipeLocalData();

      expect(result.isSuccess, isTrue);
      expect(deletion.hasPendingIdentityCleanup, isFalse);
      expect(deletion.hasPendingAnonymousBootstrap, isFalse);
      expect(AccountDeletionPendingState.isClear, isTrue);
      await expectUserBoundCleared();
      expect(gateway.currentUser?.isAnonymous, isTrue);
    },
  );

  test(
    'retryPendingIdentityCleanup completes the deletion once the identity '
    'can finally be deleted (idempotent — server deletion runs again safely)',
    () async {
      await seedUserBound();
      await auth.signInWithEmail(
        const EmailCredentials(email: 'a@b.c', password: 'x'),
      );
      gateway.deleteError = 'requires-recent-login';
      await deletion.deleteAccountAndWipeLocalData(
        reauth: const AccountReauthCredentials.email(
          EmailCredentials(email: 'a@b.c', password: 'x'),
        ),
      );
      expect(deletion.hasPendingIdentityCleanup, isTrue);

      // Simulate a successful reauth having happened — identity delete now
      // succeeds.
      gateway.deleteError = null;
      final retry = await deletion.retryPendingIdentityCleanup();

      expect(retry.isSuccess, isTrue);
      expect(deletion.hasPendingIdentityCleanup, isFalse);
      await expectUserBoundCleared();
      expect(gateway.currentUser?.isAnonymous, isTrue);
      expect(sessions.currentSession, isNotNull);
    },
  );

  test(
    'retryPendingIdentityCleanup stays pending — never wipes — if the '
    'identity still cannot be deleted',
    () async {
      await seedUserBound();
      await auth.signInWithEmail(
        const EmailCredentials(email: 'a@b.c', password: 'x'),
      );
      gateway.deleteError = 'requires-recent-login';
      await deletion.deleteAccountAndWipeLocalData(
        reauth: const AccountReauthCredentials.email(
          EmailCredentials(email: 'a@b.c', password: 'x'),
        ),
      );

      final retry = await deletion.retryPendingIdentityCleanup();

      expect(retry.isFailure, isTrue);
      expect(deletion.hasPendingIdentityCleanup, isTrue);
      expect(storage.getString('user_name'), 'Ada');
    },
  );

  test(
    'retryPendingIdentityCleanup is a no-op success when nothing is pending',
    () async {
      expect(deletion.hasPendingIdentityCleanup, isFalse);
      final retry = await deletion.retryPendingIdentityCleanup();
      expect(retry.isSuccess, isTrue);
      expect(gateway.deleteCalls, 0);
    },
  );

  test(
    'identity deleted + anonymous sign-in fails → gate stays finalizing',
    () async {
      await seedUserBound();
      await auth.signInAnonymously();
      gateway.anonSignInError = 'network-request-failed';

      final result = await deletion.deleteAccountAndWipeLocalData();

      expect(result.isFailure, isTrue);
      expect(AccountDeletionPendingState.isFinalizing, isTrue);
      expect(AccountDeletionPendingState.isClear, isFalse);
      expect(deletion.hasPendingAnonymousBootstrap, isTrue);
      expect(deletion.hasPendingIdentityCleanup, isFalse);
      await expectUserBoundCleared();
      expect(gateway.currentUser, isNull);
      expect(gateway.deleteCalls, 1);

      gateway.anonSignInError = null;
      final deletesBeforeRetry = gateway.deleteCalls;
      final anonBefore = gateway.anonSerial;
      final retry = await deletion.retryPendingIdentityCleanup();

      expect(retry.isSuccess, isTrue);
      expect(AccountDeletionPendingState.isClear, isTrue);
      expect(gateway.deleteCalls, deletesBeforeRetry);
      expect(gateway.anonSerial, anonBefore + 1);
      expect(gateway.currentUser?.isAnonymous, isTrue);
    },
  );

  test(
    'partial anonymous user + token failure: retry does not deleteAccount',
    () async {
      await seedUserBound();
      await auth.signInAnonymously();
      gateway.failIdTokenAfterAnonCreate = true;

      final result = await deletion.deleteAccountAndWipeLocalData();

      expect(result.isFailure, isTrue);
      expect(AccountDeletionPendingState.isFinalizing, isTrue);
      expect(deletion.hasPendingAnonymousBootstrap, isTrue);
      expect(gateway.currentUser?.isAnonymous, isTrue);
      final uid = gateway.currentUser!.uid;
      final deletesBefore = gateway.deleteCalls;

      gateway.failIdTokenAfterAnonCreate = false;
      final retry = await deletion.retryPendingIdentityCleanup();

      expect(retry.isSuccess, isTrue);
      expect(gateway.deleteCalls, deletesBefore);
      expect(gateway.currentUser?.uid, uid);
      expect(AccountDeletionPendingState.isClear, isTrue);
    },
  );

  group('pre-deletion reauthentication for linked users', () {
    test(
      'linked (email) user without a reauth credential is refused BEFORE '
      'any destructive call — server delete count is zero',
      () async {
        var serverCalls = 0;
        final counting = AccountDeletionService(
          auth: auth,
          storage: storage,
          secureStorage: secure,
          deleteServerData: () async {
            serverCalls++;
            return true;
          },
        );
        await seedUserBound();
        await auth.signInWithEmail(
          const EmailCredentials(email: 'a@b.c', password: 'x'),
        );

        final result = await counting.deleteAccountAndWipeLocalData();

        expect(result.isFailure, isTrue);
        expect(result.errorOrNull?.message, AuthCopy.requiresRecentLogin);
        expect(serverCalls, 0);
        expect(gateway.deleteCalls, 0);
        expect(counting.hasPendingIdentityCleanup, isFalse);
        expect(storage.getString('user_name'), 'Ada');
        expect(gateway.currentUser?.email, 'a@b.c');
      },
    );

    test(
      'reauth failure (wrong password / cancelled) leaves zero destructive '
      'calls — server delete, identity delete, wipe, and pending marker are '
      'all untouched',
      () async {
        var serverCalls = 0;
        final counting = AccountDeletionService(
          auth: auth,
          storage: storage,
          secureStorage: secure,
          deleteServerData: () async {
            serverCalls++;
            return true;
          },
        );
        await seedUserBound();
        await auth.signInWithEmail(
          const EmailCredentials(email: 'a@b.c', password: 'x'),
        );
        gateway.reauthError = 'wrong-password';

        final result = await counting.deleteAccountAndWipeLocalData(
          reauth: const AccountReauthCredentials.email(
            EmailCredentials(email: 'a@b.c', password: 'wrong'),
          ),
        );

        expect(result.isFailure, isTrue);
        expect(gateway.reauthCalls, 1);
        expect(serverCalls, 0);
        expect(gateway.deleteCalls, 0);
        expect(counting.hasPendingIdentityCleanup, isFalse);
        expect(storage.getString('user_name'), 'Ada');
        expect(gateway.currentUser?.email, 'a@b.c');
        expect(sessions.currentSession, isNotNull);
      },
    );

    test(
      'successful reauth but server-data deletion itself fails: Firebase '
      'identity remains, no local wipe, no pending marker (only a later '
      'identity-deletion failure — not a server failure — is "pending")',
      () async {
        final failingServer = AccountDeletionService(
          auth: auth,
          storage: storage,
          secureStorage: secure,
          deleteServerData: () async => false,
        );
        await seedUserBound();
        await auth.signInWithEmail(
          const EmailCredentials(email: 'a@b.c', password: 'x'),
        );

        final result = await failingServer.deleteAccountAndWipeLocalData(
          reauth: const AccountReauthCredentials.email(
            EmailCredentials(email: 'a@b.c', password: 'x'),
          ),
        );

        expect(result.isFailure, isTrue);
        expect(gateway.reauthCalls, 1);
        expect(gateway.deleteCalls, 0);
        expect(failingServer.hasPendingIdentityCleanup, isFalse);
        expect(gateway.currentUser, isNotNull);
        expect(storage.getString('user_name'), 'Ada');
      },
    );

    test(
      'successful reauth -> server delete -> identity delete -> wipe, all '
      'in order, for a linked user (full happy path)',
      () async {
        var serverCalls = 0;
        final counting = AccountDeletionService(
          auth: auth,
          storage: storage,
          secureStorage: secure,
          deleteServerData: () async {
            serverCalls++;
            return true;
          },
        );
        await seedUserBound();
        await auth.signInWithEmail(
          const EmailCredentials(email: 'a@b.c', password: 'x'),
        );

        final result = await counting.deleteAccountAndWipeLocalData(
          reauth: const AccountReauthCredentials.email(
            EmailCredentials(email: 'a@b.c', password: 'x'),
          ),
        );

        expect(result.isSuccess, isTrue);
        expect(gateway.reauthCalls, 1);
        expect(serverCalls, 1);
        expect(gateway.deleteCalls, 1);
        await expectUserBoundCleared();
        expect(gateway.currentUser?.isAnonymous, isTrue);
        expect(sessions.currentSession, isNotNull);
      },
    );

    test(
      'pending retry does NOT call deleteServerData again — server already '
      'accepted when the pending marker was written',
      () async {
        var serverCalls = 0;
        final counting = AccountDeletionService(
          auth: auth,
          storage: storage,
          secureStorage: secure,
          deleteServerData: () async {
            serverCalls++;
            return true;
          },
        );
        await seedUserBound();
        await auth.signInWithEmail(
          const EmailCredentials(email: 'a@b.c', password: 'x'),
        );
        gateway.deleteError = 'requires-recent-login';
        await counting.deleteAccountAndWipeLocalData(
          reauth: const AccountReauthCredentials.email(
            EmailCredentials(email: 'a@b.c', password: 'x'),
          ),
        );
        expect(serverCalls, 1);
        expect(counting.hasPendingIdentityCleanup, isTrue);

        gateway.deleteError = null;
        final anonBefore = gateway.anonSerial;
        final retry = await counting.retryPendingIdentityCleanup();

        expect(retry.isSuccess, isTrue);
        expect(serverCalls, 1, reason: 'no second authenticated server delete');
        expect(gateway.anonSerial, anonBefore + 1,
            reason: 'exactly one fresh anonymous session after cleanup');
        await expectUserBoundCleared();
      },
    );

    test(
      'a completed deletion leaves no Premium, gems, or memory residue — '
      'cross-checks every user-bound key the wipe is responsible for',
      () async {
        await seedUserBound();
        await storage.setInt(GemWalletStore.balanceKey, 500);
        await storage.setInt(GemWalletStore.serverBalanceCacheKey, 500);
        await storage.setString(GemWalletStore.serverBalanceOwnerKey, 'owner-a');
        await storage.setString(PersonalMemoryStore.key, 'leftover-memory');
        await auth.signInWithEmail(
          const EmailCredentials(email: 'a@b.c', password: 'x'),
        );

        final result = await deletion.deleteAccountAndWipeLocalData(
          reauth: const AccountReauthCredentials.email(
            EmailCredentials(email: 'a@b.c', password: 'x'),
          ),
        );

        expect(result.isSuccess, isTrue);
        expect(storage.getInt(GemWalletStore.balanceKey), isNull);
        expect(storage.getInt(GemWalletStore.serverBalanceCacheKey), isNull);
        expect(storage.getString(GemWalletStore.serverBalanceOwnerKey), isNull);
        expect(storage.getString(PersonalMemoryStore.key), isNull);
        // ownerKey is intentionally repopulated with the fresh anonymous
        // session's own id right after the wipe — never left pointing at
        // the deleted owner, but not null either (a new session needs an
        // owner to isolate against too).
        expect(
          storage.getString(UserLocalDataIsolation.ownerKey),
          isNot('owner-a'),
        );
        await expectUserBoundCleared();
      },
    );
  });

  group('startup pending-cleanup gate (mirrors main.dart\'s _deferredStartup)',
      () {
    test(
      'a pending marker that a no-credential retry cannot resolve stays '
      'blocking — the startup gate must not treat this as a healthy account',
      () async {
        await seedUserBound();
        await auth.signInWithEmail(
          const EmailCredentials(email: 'a@b.c', password: 'x'),
        );
        gateway.deleteError = 'requires-recent-login';
        await deletion.deleteAccountAndWipeLocalData(
          reauth: const AccountReauthCredentials.email(
            EmailCredentials(email: 'a@b.c', password: 'x'),
          ),
        );
        expect(deletion.hasPendingIdentityCleanup, isTrue);

        // Exactly what main.dart's startup gate does: one automatic retry,
        // no credentials available (no reauth UI wired up yet).
        await deletion.retryPendingIdentityCleanup();

        expect(
          deletion.hasPendingIdentityCleanup,
          isTrue,
          reason: 'still requires a real reauth the automatic retry cannot '
              'supply — the gate must stay blocked, never fall through to '
              'normal anonymous bootstrap',
        );
      },
    );

    test(
      'once the identity is actually deletable, the automatic startup '
      'retry clears the gate with no infinite loop (one call, one result)',
      () async {
        await seedUserBound();
        await auth.signInWithEmail(
          const EmailCredentials(email: 'a@b.c', password: 'x'),
        );
        gateway.deleteError = 'requires-recent-login';
        await deletion.deleteAccountAndWipeLocalData(
          reauth: const AccountReauthCredentials.email(
            EmailCredentials(email: 'a@b.c', password: 'x'),
          ),
        );
        gateway.deleteError = null;

        await deletion.retryPendingIdentityCleanup();

        expect(deletion.hasPendingIdentityCleanup, isFalse);
        expect(gateway.deleteCalls, 2, reason: 'exactly one retry attempt');
      },
    );
  });

  group('linked Google / Apple native provider reauth', () {
    test('Google reauth success → server → identity → wipe', () async {
      var serverCalls = 0;
      final counting = AccountDeletionService(
        auth: auth,
        storage: storage,
        secureStorage: secure,
        deleteServerData: () async {
          serverCalls++;
          return true;
        },
      );
      await seedUserBound();
      await auth.signInWithGoogle(
        const OAuthCredentials(idToken: 'g-id'),
      );
      expect(auth.currentReauthMethods, [AccountReauthMethod.google]);

      final result = await counting.deleteAccountAndWipeLocalData(
        reauth: const AccountReauthCredentials.google(),
      );

      expect(result.isSuccess, isTrue);
      expect(gateway.reauthCalls, 1);
      expect(serverCalls, 1);
      expect(gateway.deleteCalls, 1);
      await expectUserBoundCleared();
    });

    test('Google reauth cancel/failure: server=0 identity=0 wipe=0 pending=false',
        () async {
      var serverCalls = 0;
      final counting = AccountDeletionService(
        auth: auth,
        storage: storage,
        secureStorage: secure,
        deleteServerData: () async {
          serverCalls++;
          return true;
        },
      );
      await seedUserBound();
      await auth.signInWithGoogle(
        const OAuthCredentials(idToken: 'g-id'),
      );
      gateway.reauthError = 'user-cancelled';

      final result = await counting.deleteAccountAndWipeLocalData(
        reauth: const AccountReauthCredentials.google(),
      );

      expect(result.isFailure, isTrue);
      expect(serverCalls, 0);
      expect(gateway.deleteCalls, 0);
      expect(counting.hasPendingIdentityCleanup, isFalse);
      expect(storage.getString('user_name'), 'Ada');
    });

    test('Apple reauth success → wipe', () async {
      await seedUserBound();
      await auth.signInWithApple(
        const OAuthCredentials(idToken: 'a-id'),
      );
      expect(auth.currentReauthMethods, [AccountReauthMethod.apple]);

      final result = await deletion.deleteAccountAndWipeLocalData(
        reauth: const AccountReauthCredentials.apple(),
      );

      expect(result.isSuccess, isTrue);
      expect(gateway.reauthCalls, 1);
      await expectUserBoundCleared();
    });

    test('Apple reauth failure leaves zero destructive work', () async {
      var serverCalls = 0;
      final counting = AccountDeletionService(
        auth: auth,
        storage: storage,
        secureStorage: secure,
        deleteServerData: () async {
          serverCalls++;
          return true;
        },
      );
      await seedUserBound();
      await auth.signInWithApple(
        const OAuthCredentials(idToken: 'a-id'),
      );
      gateway.reauthError = 'canceled';

      final result = await counting.deleteAccountAndWipeLocalData(
        reauth: const AccountReauthCredentials.apple(),
      );

      expect(result.isFailure, isTrue);
      expect(serverCalls, 0);
      expect(gateway.deleteCalls, 0);
      expect(counting.hasPendingIdentityCleanup, isFalse);
    });

    test('multi-provider snapshot exposes ordered reauth methods', () async {
      await gateway.signInMultiLinked();
      expect(
        auth.currentReauthMethods,
        [
          AccountReauthMethod.google,
          AccountReauthMethod.apple,
          AccountReauthMethod.email,
        ],
      );
      expect(
        AccountReauthMethodResolver.preferred(auth.currentReauthMethods),
        AccountReauthMethod.google,
      );
    });
  });

  test('mapDelete maps requires-recent-login and no-current-user', () {
    expect(
      FirebaseAuthErrors.mapDelete(
        AuthGatewayException(
          'requires-recent-login',
          code: 'requires-recent-login',
        ),
      ).message,
      AuthCopy.requiresRecentLogin,
    );
    expect(
      FirebaseAuthErrors.mapDelete(
        AuthGatewayException('no-current-user', code: 'no-current-user'),
      ).message,
      AuthCopy.noCurrentUser,
    );
  });
}

/// Throws when [remove] is called for any key in [failingKeys], then
/// behaves normally for everything else — simulates a real local-wipe
/// write failure at an EXACT key, independent of whether the identity
/// deletion itself succeeded.
class _KeyFailingStorage extends LocalStorage {
  _KeyFailingStorage(super.prefs, {required this.failingKeys});

  final Set<String> failingKeys;

  @override
  Future<bool> remove(String key) async {
    if (failingKeys.contains(key)) {
      throw StateError('simulated remove failure for $key');
    }
    return super.remove(key);
  }
}

/// Fails a `setBool` write for an exact key, then behaves normally for
/// everything else — for tests that specifically need to interrupt a
/// marker being ESTABLISHED (as opposed to [_KeyFailingStorage], which
/// targets a key's REMOVAL).
class _BoolWriteFailingStorage extends LocalStorage {
  _BoolWriteFailingStorage(super.prefs, {required this.failingKey});

  final String failingKey;

  @override
  Future<bool> setBool(String key, bool value) async {
    if (key == failingKey) {
      throw StateError('simulated setBool failure for $key');
    }
    return super.setBool(key, value);
  }
}

class _DeletionGateway implements FirebaseAuthGateway {
  final _controller = StreamController<FirebaseAuthUserSnapshot?>.broadcast();
  FirebaseAuthUserSnapshot? _user;
  String? deleteError;
  bool clearUserBeforeThrowing = false;
  int deleteCalls = 0;
  int anonSerial = 0;
  String? anonSignInError;
  bool failIdTokenAfterAnonCreate = false;

  @override
  bool get isInitialized => true;

  @override
  FirebaseAuthUserSnapshot? get currentUser => _user;

  @override
  Stream<FirebaseAuthUserSnapshot?> authStateChanges() => _controller.stream;

  @override
  Future<String?> currentIdToken({bool forceRefresh = false}) async {
    if (_user == null) return null;
    if (failIdTokenAfterAnonCreate && _user!.isAnonymous) return null;
    return _idToken;
  }

  @override
  Future<FirebaseAuthUserSnapshot> signInAnonymously() async {
    if (anonSignInError != null) {
      throw AuthGatewayException(anonSignInError!, code: anonSignInError);
    }
    anonSerial++;
    _user = FirebaseAuthUserSnapshot(
      uid: 'anon-$anonSerial',
      isAnonymous: true,
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<FirebaseAuthUserSnapshot> signInWithEmail({
    required String email,
    required String password,
  }) async {
    _user = FirebaseAuthUserSnapshot(
      uid: 'mail-1',
      email: email,
      providerIds: const ['password'],
    );
    _controller.add(_user);
    return _user!;
  }

  Future<FirebaseAuthUserSnapshot> signInMultiLinked() async {
    _user = const FirebaseAuthUserSnapshot(
      uid: 'multi-1',
      email: 'm@b.c',
      providerIds: ['google.com', 'password', 'apple.com'],
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<FirebaseAuthUserSnapshot> signInWithGoogle({
    required String idToken,
    String? accessToken,
  }) async {
    _user = const FirebaseAuthUserSnapshot(
      uid: 'google-1',
      email: 'g@b.c',
      providerIds: ['google.com'],
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<FirebaseAuthUserSnapshot> signInWithApple({required String idToken}) async {
    _user = const FirebaseAuthUserSnapshot(
      uid: 'apple-1',
      email: 'a@privaterelay.appleid.com',
      providerIds: ['apple.com'],
    );
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteCurrentUser() async {
    deleteCalls++;
    if (clearUserBeforeThrowing) {
      _user = null;
      _controller.add(null);
    }
    if (deleteError != null) {
      throw AuthGatewayException(deleteError!, code: deleteError);
    }
    if (_user == null) {
      throw AuthGatewayException('no-current-user', code: 'no-current-user');
    }
    _user = null;
    _controller.add(null);
  }

  String? reauthError;
  int reauthCalls = 0;

  @override
  Future<void> reauthenticateWithGoogle({
    required String idToken,
    String? accessToken,
  }) => _reauth();

  @override
  Future<void> reauthenticateWithGoogleProvider() => _reauth();

  @override
  Future<void> reauthenticateWithApple({required String idToken}) => _reauth();

  @override
  Future<void> reauthenticateWithAppleProvider() => _reauth();

  @override
  Future<void> reauthenticateWithEmail({
    required String email,
    required String password,
  }) => _reauth();

  Future<void> _reauth() async {
    reauthCalls++;
    if (reauthError != null) {
      throw AuthGatewayException(reauthError!, code: reauthError);
    }
  }
}

class _MemTokens implements TokenManager {
  String? access;
  String? refresh;

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async => access;

  @override
  Future<String?> getRefreshToken() async => refresh;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    access = null;
    refresh = null;
  }

  @override
  Future<bool> hasValidAccessToken() async =>
      access != null && access!.isNotEmpty;
}
