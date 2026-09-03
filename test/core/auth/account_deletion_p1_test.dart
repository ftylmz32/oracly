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
      isolation: UserLocalDataIsolation(
        storage,
        secureStorage: secure,
      ),
    );
    deletion = AccountDeletionService(
      auth: auth,
      storage: storage,
      secureStorage: secure,
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

  void expectUserBoundCleared() {
    expect(storage.getStringList('or_reading_history'), isEmpty);
    expect(storage.getStringList(TarotLocalDataSource.historyKey), isEmpty);
    expect(storage.getString(LocalFavoriteMomentsRepository.key), isNull);
    expect(storage.getString(PersonalMemoryStore.key), isNull);
    expect(storage.getString('user_name'), isNull);
    expect(premiumRepo.readPurchaseCredentials(), isNull);
    expect(premiumRepo.isActiveNow, isFalse);
  }

  test('anonymous deletion success wipes local and bootstraps fresh session',
      () async {
    await seedUserBound();
    await auth.signInAnonymously();
    expect(gateway.currentUser?.isAnonymous, isTrue);

    final result = await deletion.deleteAccountAndWipeLocalData();

    expect(result.isSuccess, isTrue);
    expectUserBoundCleared();
    expect(storage.getString('settings_language'), 'en');
    expect(storage.getBool('onboarding_completed'), isTrue);
    expect(sessions.currentSession, isNotNull);
    expect(gateway.currentUser, isNotNull);
    expect(gateway.deleteCalls, 1);
  });

  test('authenticated deletion success clears premium credentials and history',
      () async {
    await seedUserBound();
    final signedIn = await auth.signInWithEmail(
      const EmailCredentials(email: 'a@b.c', password: 'x'),
    );
    expect(signedIn.isSuccess, isTrue);
    expect(gateway.currentUser?.isAnonymous, isFalse);

    final result = await deletion.deleteAccountAndWipeLocalData();

    expect(result.isSuccess, isTrue);
    expectUserBoundCleared();
    expect(gateway.deleteCalls, 1);
    expect(gateway.currentUser?.isAnonymous, isTrue);
  });

  test('Firebase deletion failure does not wipe or claim success', () async {
    await seedUserBound();
    await auth.signInAnonymously();
    gateway.deleteError = 'network-request-failed';

    final result = await deletion.deleteAccountAndWipeLocalData();

    expect(result.isFailure, isTrue);
    expect(result.errorOrNull?.message, isNot(AuthCopy.signedOut));
    expect(storage.getStringList('or_reading_history'), isNotEmpty);
    expect(storage.getString('user_name'), 'Ada');
    expect(premiumRepo.readPurchaseCredentials(), isNotNull);
    expect(gateway.currentUser, isNotNull);
    expect(sessions.currentSession, isNotNull);
  });

  test('requires-recent-login fails honestly without wipe or logout', () async {
    await seedUserBound();
    await auth.signInWithEmail(
      const EmailCredentials(email: 'a@b.c', password: 'x'),
    );
    gateway.deleteError = 'requires-recent-login';

    final result = await deletion.deleteAccountAndWipeLocalData();

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

  test('deleteAccount alone never pretends logout is deletion success',
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
  });

  test('mapDelete maps requires-recent-login and no-current-user', () {
    expect(
      FirebaseAuthErrors.mapDelete(
        AuthGatewayException('requires-recent-login',
            code: 'requires-recent-login'),
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
  }) =>
      signInAnonymously();

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