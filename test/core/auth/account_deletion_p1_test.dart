/// Account deletion: remote-first, honest failures, local wipe only after success.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/account_deletion_service.dart';
import 'package:oracly_new/core/auth/auth_copy.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_errors.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_gateway.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_service.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_user.dart';
import 'package:oracly_new/core/auth/firebase/firebase_id_token_manager.dart';
import 'package:oracly_new/core/auth/models/auth_credentials.dart';
import 'package:oracly_new/core/auth/session_manager.dart';
import 'package:oracly_new/core/auth/token_manager.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
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

  tearDown(() => auth.dispose());

  Future<void> seedUserBound() async {
    await storage.setStringList('or_reading_history', const ['r1']);
    await storage.setStringList(TarotLocalDataSource.historyKey, const ['t1']);
    await storage.setString(LocalFavoriteMomentsRepository.key, 'fav');
    await storage.setString(PersonalMemoryStore.key, 'mem');
    await storage.setString('user_name', 'Ada');
    await storage.setString('settings_language', 'en');
    await storage.setBool('onboarding_completed', true);
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
  }

  test(
    'anonymous deletion success wipes local and bootstraps fresh session',
    () async {
      await seedUserBound();
      await auth.signInAnonymously();
      expect(gateway.currentUser?.isAnonymous, isTrue);

      final result = await deletion.deleteAccountAndWipeLocalData();

      expect(result.isSuccess, isTrue);
      await expectUserBoundCleared();
      expect(storage.getString('settings_language'), 'en');
      expect(storage.getBool('onboarding_completed'), isTrue);
      expect(sessions.currentSession, isNotNull);
      expect(gateway.currentUser, isNotNull);
      expect(gateway.deleteCalls, 1);
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
    'a plain (non-reauth) delete failure does NOT set the pending marker — '
    'only the specific requires-recent-login case does',
    () async {
      await seedUserBound();
      await auth.signInAnonymously();
      gateway.deleteError = 'network-request-failed';

      await deletion.deleteAccountAndWipeLocalData();

      expect(deletion.hasPendingIdentityCleanup, isFalse);
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
      'duplicate server-delete retry is idempotent — retryPendingIdentityCleanup '
      'safely calls deleteServerData a second time after it already succeeded',
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
        final retry = await counting.retryPendingIdentityCleanup();

        expect(retry.isSuccess, isTrue);
        expect(serverCalls, 2, reason: 'idempotent second call, not skipped');
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

class _DeletionGateway implements FirebaseAuthGateway {
  final _controller = StreamController<FirebaseAuthUserSnapshot?>.broadcast();
  FirebaseAuthUserSnapshot? _user;
  String? deleteError;
  int deleteCalls = 0;
  int anonSerial = 0;

  @override
  bool get isInitialized => true;

  @override
  FirebaseAuthUserSnapshot? get currentUser => _user;

  @override
  Stream<FirebaseAuthUserSnapshot?> authStateChanges() => _controller.stream;

  @override
  Future<String?> currentIdToken({bool forceRefresh = false}) async =>
      _user == null ? null : _idToken;

  @override
  Future<FirebaseAuthUserSnapshot> signInAnonymously() async {
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
    _user = FirebaseAuthUserSnapshot(uid: 'mail-1', email: email);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<FirebaseAuthUserSnapshot> signInWithGoogle({
    required String idToken,
    String? accessToken,
  }) => signInAnonymously();

  @override
  Future<FirebaseAuthUserSnapshot> signInWithApple({required String idToken}) =>
      signInAnonymously();

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteCurrentUser() async {
    deleteCalls++;
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
  Future<void> reauthenticateWithApple({required String idToken}) => _reauth();

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
