/// P0-2 — bootstrapCreationArmedKey is real deletion provenance.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/account_deletion_finalizer.dart';
import 'package:oracly_new/core/auth/account_deletion_markers.dart';
import 'package:oracly_new/core/auth/account_deletion_pending_state.dart';
import 'package:oracly_new/core/auth/account_deletion_service.dart';
import 'package:oracly_new/core/auth/account_deletion_target.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_gateway.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_service.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_user.dart';
import 'package:oracly_new/core/auth/firebase/firebase_id_token_manager.dart';
import 'package:oracly_new/core/auth/session_manager.dart';
import 'package:oracly_new/core/auth/token_manager.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/false_return_local_storage.dart';

const _idToken = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.e30.sig';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    AccountDeletionPendingState.resetForTest();
    AccountDeletionPendingState.markClear();
  });

  test(
    'A: persistBootstrap ok but armed remove returns false — NOT clear; '
    'restart stays finalizing; healthy retry clears',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = FalseReturnLocalStorage(prefs);
      final gateway = _Gateway();
      final auth = FirebaseAuthService(
        gateway: gateway,
        tokens: _MemTokens(),
        sessions: InMemorySessionManager(_MemTokens()),
        isolation: UserLocalDataIsolation(
          storage,
          secureStorage: InMemorySecureStorage(),
        ),
      );
      await storage.setBool(
        AccountDeletionFinalizer.anonymousBootstrapKey,
        true,
      );
      storage.falseReturnRemoveKeys.add(
        AccountDeletionFinalizer.bootstrapCreationArmedKey,
      );

      final first = await AccountDeletionFinalizer.completeAnonymousBootstrap(
        auth: auth,
        storage: storage,
        identityCleanupKey: AccountDeletionService.pendingIdentityCleanupKey,
      );

      expect(first.isFailure, isTrue);
      expect(
        storage.getBool(AccountDeletionFinalizer.anonymousBootstrapKey),
        isTrue,
      );
      expect(
        AccountDeletionMarkers.isExactlyTrue(
          storage,
          AccountDeletionFinalizer.bootstrapCreationArmedKey,
        ),
        isTrue,
      );
      expect(AccountDeletionPendingState.isFinalizing, isTrue);
      final createdUid = gateway.currentUser!.uid;

      AccountDeletionPendingState.resetForTest();
      final restart =
          await AccountDeletionPendingState.resolveFromLocalStorage(storage);
      expect(restart, AccountDeletionGateResolveStatus.finalizing);

      storage.falseReturnRemoveKeys.clear();
      final retry = await AccountDeletionFinalizer.completeAnonymousBootstrap(
        auth: auth,
        storage: storage,
        identityCleanupKey: AccountDeletionService.pendingIdentityCleanupKey,
      );
      expect(retry.isSuccess, isTrue);
      expect(gateway.currentUser?.uid, createdUid);
      expect(
        storage.getBool(AccountDeletionFinalizer.anonymousBootstrapKey),
        isNull,
      );
      expect(
        AccountDeletionMarkers.read(
          storage,
          AccountDeletionFinalizer.bootstrapCreationArmedKey,
        ),
        MarkerRead.absent,
      );
      expect(AccountDeletionPendingState.isClear, isTrue);
    },
  );

  test(
    'B: stale armed-only residue — reconcile removes it, no anon create',
    () async {
      SharedPreferences.setMockInitialValues({
        AccountDeletionFinalizer.bootstrapCreationArmedKey: true,
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = FalseReturnLocalStorage(prefs);
      final gateway = _Gateway();
      final deletion = AccountDeletionService(
        auth: FirebaseAuthService(
          gateway: gateway,
          tokens: _MemTokens(),
          sessions: InMemorySessionManager(_MemTokens()),
          isolation: UserLocalDataIsolation(
            storage,
            secureStorage: InMemorySecureStorage(),
          ),
        ),
        storage: storage,
        secureStorage: InMemorySecureStorage(),
        deleteServerData: (_) async => true,
      );

      final status = await AccountDeletionPendingState.resolveFromLocalStorage(
        storage,
      );
      expect(status, AccountDeletionGateResolveStatus.integrityRecovery);
      expect(gateway.anonSerial, 0);
      expect(gateway.deleteCalls, 0);

      await AccountDeletionPendingState.resolveAndReconcile(storage, deletion);
      expect(
        AccountDeletionMarkers.read(
          storage,
          AccountDeletionFinalizer.bootstrapCreationArmedKey,
        ),
        MarkerRead.absent,
      );
      expect(AccountDeletionPendingState.isClear, isTrue);
      expect(gateway.anonSerial, 0);
      expect(gateway.deleteCalls, 0);
    },
  );

  test('C: corrupt armed key — integrityRecovery, zero destructive work',
      () async {
    final storage = LocalStorage.ephemeral({
      AccountDeletionFinalizer.bootstrapCreationArmedKey: 'not-a-bool',
    });
    final gateway = _Gateway();
    final deletion = AccountDeletionService(
      auth: FirebaseAuthService(
        gateway: gateway,
        tokens: _MemTokens(),
        sessions: InMemorySessionManager(_MemTokens()),
        isolation: UserLocalDataIsolation(
          storage,
          secureStorage: InMemorySecureStorage(),
        ),
      ),
      storage: storage,
      secureStorage: InMemorySecureStorage(),
      deleteServerData: (_) async => true,
    );

    final status =
        await AccountDeletionPendingState.resolveFromLocalStorage(storage);
    expect(status, AccountDeletionGateResolveStatus.integrityRecovery);
    expect(deletion.hasCorruptDeletionMarker, isTrue);

    await AccountDeletionPendingState.resolveAndReconcile(storage, deletion);
    expect(gateway.anonSerial, 0);
    expect(gateway.deleteCalls, 0);
    expect(
      AccountDeletionMarkers.read(
        storage,
        AccountDeletionFinalizer.bootstrapCreationArmedKey,
      ),
      MarkerRead.corrupt,
    );
  });

  test(
    'D: second deletion never accepts unrelated pre-existing anon because '
    'of stale armed provenance from a prior cycle',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = FalseReturnLocalStorage(prefs);
      final gateway = _Gateway();
      final auth = FirebaseAuthService(
        gateway: gateway,
        tokens: _MemTokens(),
        sessions: InMemorySessionManager(
          FirebaseIdTokenManager(gateway, fallback: _MemTokens()),
        ),
        isolation: UserLocalDataIsolation(
          storage,
          secureStorage: InMemorySecureStorage(),
        ),
      );

      await storage.setBool(
        AccountDeletionFinalizer.anonymousBootstrapKey,
        true,
      );
      storage.falseReturnRemoveKeys.add(
        AccountDeletionFinalizer.bootstrapCreationArmedKey,
      );
      final first = await AccountDeletionFinalizer.completeAnonymousBootstrap(
        auth: auth,
        storage: storage,
        identityCleanupKey: AccountDeletionService.pendingIdentityCleanupKey,
      );
      expect(first.isFailure, isTrue);
      expect(
        AccountDeletionMarkers.isExactlyTrue(
          storage,
          AccountDeletionFinalizer.bootstrapCreationArmedKey,
        ),
        isTrue,
      );

      storage.falseReturnRemoveKeys.clear();
      final healed = await AccountDeletionFinalizer.completeAnonymousBootstrap(
        auth: auth,
        storage: storage,
        identityCleanupKey: AccountDeletionService.pendingIdentityCleanupKey,
      );
      expect(healed.isSuccess, isTrue);
      expect(AccountDeletionPendingState.isClear, isTrue);
      expect(
        AccountDeletionMarkers.read(
          storage,
          AccountDeletionFinalizer.bootstrapCreationArmedKey,
        ),
        MarkerRead.absent,
      );

      gateway.forceUser(
        const FirebaseAuthUserSnapshot(
          uid: 'unrelated-preexisting',
          isAnonymous: true,
        ),
      );
      await storage.setBool(
        AccountDeletionFinalizer.anonymousBootstrapKey,
        true,
      );
      final second = await AccountDeletionFinalizer.completeAnonymousBootstrap(
        auth: auth,
        storage: storage,
        identityCleanupKey: AccountDeletionService.pendingIdentityCleanupKey,
      );
      expect(second.isFailure, isTrue);
      expect(gateway.currentUser?.uid, 'unrelated-preexisting');
      expect(gateway.anonSerial, 1);
      expect(AccountDeletionTarget.readBootstrapUid(storage), isNull);
    },
  );
}

class _Gateway implements FirebaseAuthGateway {
  final _controller = StreamController<FirebaseAuthUserSnapshot?>.broadcast();
  FirebaseAuthUserSnapshot? _user;
  int deleteCalls = 0;
  int anonSerial = 0;

  @override
  bool get isInitialized => true;

  @override
  FirebaseAuthUserSnapshot? get currentUser => _user;

  void forceUser(FirebaseAuthUserSnapshot? user) {
    _user = user;
    _controller.add(_user);
  }

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
  }) async =>
      throw UnimplementedError();

  @override
  Future<FirebaseAuthUserSnapshot> signInWithGoogle({
    required String idToken,
    String? accessToken,
  }) async =>
      throw UnimplementedError();

  @override
  Future<FirebaseAuthUserSnapshot> signInWithApple({
    required String idToken,
  }) async =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteCurrentUser() async {
    deleteCalls++;
    _user = null;
    _controller.add(null);
  }

  @override
  Future<void> reauthenticateWithGoogle({
    required String idToken,
    String? accessToken,
  }) async {}

  @override
  Future<void> reauthenticateWithGoogleProvider() async {}

  @override
  Future<void> reauthenticateWithApple({required String idToken}) async {}

  @override
  Future<void> reauthenticateWithAppleProvider() async {}

  @override
  Future<void> reauthenticateWithEmail({
    required String email,
    required String password,
  }) async {}
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
