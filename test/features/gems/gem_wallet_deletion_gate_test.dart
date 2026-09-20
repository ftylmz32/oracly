/// Gem / auth bootstrap must not run while deletion gate is unresolved/blocked.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/account_deletion_pending_state.dart';
import 'package:oracly_new/core/auth/auth_service.dart';
import 'package:oracly_new/core/auth/models/account_reauth_method.dart';
import 'package:oracly_new/core/auth/models/auth_credentials.dart';
import 'package:oracly_new/core/auth/models/auth_session.dart';
import 'package:oracly_new/core/network/api_result.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_bootstrap.dart';

void main() {
  setUp(() {
    AccountDeletionPendingState.beginStartup();
  });

  tearDown(() {
    AccountDeletionPendingState.markClear();
  });

  test('ensureReady returns false and skips auth while unresolved', () async {
    final auth = _CountingAuth();
    expect(AccountDeletionPendingState.isUnresolved, isTrue);

    final ok = await GemWalletBootstrap.ensureReady(
      config: const AiRuntimeConfig(
        proxyUrl: 'https://proxy.example/v1/ai/complete',
      ),
      auth: auth,
    );

    expect(ok, isFalse);
    expect(auth.ensureAnonymousCalls, 0);
    expect(auth.signInAnonymousCalls, 0);
  });

  test('ensureReady returns false and skips auth while blocked', () async {
    AccountDeletionPendingState.markBlocked();
    final auth = _CountingAuth();

    final ok = await GemWalletBootstrap.ensureReady(
      config: const AiRuntimeConfig(
        proxyUrl: 'https://proxy.example/v1/ai/complete',
      ),
      auth: auth,
    );

    expect(ok, isFalse);
    expect(auth.ensureAnonymousCalls, 0);
  });

  test('allowsOwnerBoundExperience is false until clear', () {
    expect(AccountDeletionPendingState.allowsOwnerBoundExperience, isFalse);
    AccountDeletionPendingState.markBlocked();
    expect(AccountDeletionPendingState.allowsOwnerBoundExperience, isFalse);
    AccountDeletionPendingState.markClear();
    expect(AccountDeletionPendingState.allowsOwnerBoundExperience, isTrue);
  });
}

class _CountingAuth implements AuthService {
  int ensureAnonymousCalls = 0;
  int signInAnonymousCalls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<ApiResult<AuthSession>> ensureAnonymousSession() async {
    ensureAnonymousCalls++;
    return ApiSuccess(_session);
  }

  @override
  Future<ApiResult<AuthSession>> signInAnonymously() async {
    signInAnonymousCalls++;
    return ApiSuccess(_session);
  }

  @override
  Future<ApiResult<AuthSession>> createGuestSession() => signInAnonymously();

  @override
  Future<ApiResult<AuthSession>> refreshSession() async => ApiSuccess(_session);

  @override
  Future<ApiResult<AuthSession>> signInWithEmail(EmailCredentials c) async =>
      ApiSuccess(_session);

  @override
  Future<ApiResult<AuthSession>> signInWithGoogle(OAuthCredentials c) async =>
      ApiSuccess(_session);

  @override
  Future<ApiResult<AuthSession>> signInWithApple(OAuthCredentials c) async =>
      ApiSuccess(_session);

  @override
  Future<ApiResult<bool>> signOut() async => const ApiSuccess(true);

  @override
  Future<ApiResult<bool>> deleteAccount() async => const ApiSuccess(true);

  @override
  bool get isCurrentUserAnonymous => true;

  @override
  bool get hasCurrentIdentity => true;

  @override
  List<AccountReauthMethod> get currentReauthMethods => const [];

  @override
  String? get currentUserEmail => null;

  @override
  Future<ApiResult<bool>> reauthenticate(
    AccountReauthCredentials credentials,
  ) async =>
      const ApiSuccess(true);

  AuthSession get _session => AuthSession(
        userId: 'u1',
        provider: AuthProviderKind.anonymous,
        accessToken: 'a',
        refreshToken: 'r',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
        isGuest: true,
      );
}
