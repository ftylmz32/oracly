/// Real AuthService implementation. Screens depend on AuthService only.
library;

import 'dart:async';

import '../../network/api_result.dart';
import '../../network/network_exception.dart';
import '../auth_copy.dart';
import '../auth_service.dart';
import '../models/account_reauth_method.dart';
import '../models/auth_credentials.dart';
import '../models/auth_session.dart';
import '../session_manager.dart';
import '../token_manager.dart';
import '../user_local_data_isolation.dart';
import '../user_local_data_isolation_result.dart';
import 'firebase_account_deletion.dart';
import 'firebase_auth_errors.dart';
import 'firebase_auth_gateway.dart';
import 'firebase_auth_user.dart';
import 'firebase_session_mapper.dart';

class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    required FirebaseAuthGateway gateway,
    TokenManager? tokens,
    SessionManager? sessions,
    UserLocalDataIsolation? isolation,
  })  : _gateway = gateway,
        _tokens = tokens,
        _sessions = sessions,
        _isolation = isolation {
    _sub = _gateway.authStateChanges().listen(_syncSession);
  }

  final FirebaseAuthGateway _gateway;
  final TokenManager? _tokens;
  final SessionManager? _sessions;
  final UserLocalDataIsolation? _isolation;
  StreamSubscription<FirebaseAuthUserSnapshot?>? _sub;

  @override
  bool get isConfigured => _gateway.isInitialized;

  void dispose() => _sub?.cancel();

  @override
  Future<ApiResult<AuthSession>> signInAnonymously() {
    return _sign(() => _gateway.signInAnonymously());
  }

  @override
  Future<ApiResult<AuthSession>> createGuestSession() => signInAnonymously();

  @override
  Future<ApiResult<AuthSession>> ensureAnonymousSession() {
    final user = _gateway.currentUser;
    if (user != null) return _sessionFromUser(user);
    return signInAnonymously();
  }

  @override
  Future<ApiResult<AuthSession>> signInWithEmail(EmailCredentials credentials) {
    return _sign(
      () => _gateway.signInWithEmail(
        email: credentials.email,
        password: credentials.password,
      ),
      provider: AuthProviderKind.email,
    );
  }

  @override
  Future<ApiResult<AuthSession>> signInWithGoogle(OAuthCredentials credentials) {
    return _sign(
      () => _gateway.signInWithGoogle(
        idToken: credentials.idToken,
        accessToken: credentials.accessToken,
      ),
      provider: AuthProviderKind.google,
    );
  }

  @override
  Future<ApiResult<AuthSession>> signInWithApple(OAuthCredentials credentials) {
    return _sign(
      () => _gateway.signInWithApple(idToken: credentials.idToken),
      provider: AuthProviderKind.apple,
    );
  }

  @override
  Future<ApiResult<AuthSession>> refreshSession() async {
    return _sessionFromUser(
      _gateway.currentUser,
      forceRefresh: true,
      provider: _sessions?.currentSession?.provider ?? AuthProviderKind.anonymous,
    );
  }

  @override
  Future<ApiResult<bool>> signOut() async {
    await _gateway.signOut();
    await _sessions?.clearSession();
    await _tokens?.clearTokens();
    return const ApiSuccess(true);
  }

  @override
  Future<ApiResult<bool>> deleteAccount() {
    return FirebaseAccountDeletion.run(
      gateway: _gateway,
      sessions: _sessions,
      tokens: _tokens,
    );
  }

  @override
  bool get isCurrentUserAnonymous => _gateway.currentUser?.isAnonymous ?? true;

  @override
  bool get hasCurrentIdentity => _gateway.currentUser != null;

  @override
  List<AccountReauthMethod> get currentReauthMethods =>
      _gateway.currentUser?.reauthMethods ?? const [];

  @override
  String? get currentUserEmail => _gateway.currentUser?.email;

  @override
  Future<ApiResult<bool>> reauthenticate(
    AccountReauthCredentials credentials,
  ) async {
    try {
      switch (credentials.provider) {
        case AuthProviderKind.google:
          if (credentials.usesNativeProviderFlow) {
            await _gateway.reauthenticateWithGoogleProvider();
          } else {
            final oauth = credentials.oauth!;
            await _gateway.reauthenticateWithGoogle(
              idToken: oauth.idToken,
              accessToken: oauth.accessToken,
            );
          }
        case AuthProviderKind.apple:
          if (credentials.usesNativeProviderFlow) {
            await _gateway.reauthenticateWithAppleProvider();
          } else {
            await _gateway.reauthenticateWithApple(
              idToken: credentials.oauth!.idToken,
            );
          }
        case AuthProviderKind.email:
          final email = credentials.email!;
          await _gateway.reauthenticateWithEmail(
            email: email.email,
            password: email.password,
          );
        case AuthProviderKind.anonymous:
        case AuthProviderKind.guest:
          return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
      }
      return const ApiSuccess(true);
    } on AuthGatewayException catch (e) {
      return ApiFailure(FirebaseAuthErrors.map(e));
    } catch (_) {
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
  }

  Future<ApiResult<AuthSession>> _sign(
    Future<FirebaseAuthUserSnapshot> Function() action, {
    AuthProviderKind provider = AuthProviderKind.anonymous,
  }) async {
    try {
      final user = await action();
      return _sessionFromUser(user, provider: provider);
    } on AuthGatewayException catch (e) {
      return ApiFailure(FirebaseAuthErrors.map(e));
    } catch (_) {
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
  }

  Future<ApiResult<AuthSession>> _sessionFromUser(
    FirebaseAuthUserSnapshot? user, {
    bool forceRefresh = false,
    AuthProviderKind provider = AuthProviderKind.anonymous,
  }) async {
    if (user == null) {
      return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
    }
    try {
      final token = await _gateway.currentIdToken(forceRefresh: forceRefresh);
      if (token == null || token.isEmpty || token.startsWith('mock_')) {
        return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
      }
      // Captured BEFORE isolation runs: whether this Firebase snapshot is
      // for a genuinely DIFFERENT identity than whatever application
      // session is currently authoritative. A same-uid transient failure
      // (e.g. a refresh hiccup) may safely leave that same-user session
      // in place; a DIFFERENT uid must never leave the OLD uid's session
      // sitting there once we know the current Firebase identity is not
      // that uid any more — Firebase-uid-B + application-session-uid-A is
      // not a safe state, even though B itself was correctly never
      // committed either.
      final previousSessionUid = _sessions?.currentSession?.userId;
      final isDifferentUid =
          previousSessionUid != null && previousSessionUid != user.uid;

      // Local ownership isolation must be PROVEN before this session is
      // ever published. Publishing first and isolating after (the prior
      // order) let the app observe a "successful" session for a new
      // owner while a prior owner's account-scoped residue could still be
      // sitting under it. Never let an isolation failure — of any kind —
      // escape as an unhandled exception into the auth-state listener;
      // it always resolves to an honest ApiFailure instead.
      UserLocalDataIsolationResult? isolationResult;
      try {
        isolationResult = await _isolation?.onSignedIn(user.uid);
      } catch (_) {
        if (isDifferentUid) await _sessions?.clearSession();
        return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
      }
      if (isolationResult != null && !isolationResult.success) {
        // Isolation for the (different) incoming uid failed — the OLD
        // uid's session must not remain authoritative under a current
        // Firebase identity that is no longer that uid. ownerKey itself
        // is untouched by this — UserLocalDataIsolation already left it
        // at the prior owner as the durable residue-safety signal.
        if (isDifferentUid) await _sessions?.clearSession();
        return ApiFailure(NetworkException.unauthorized(AuthCopy.failed));
      }
      final session = FirebaseSessionMapper.fromUser(
        user: user,
        idToken: token,
        provider: provider,
      );
      await _sessions?.setSession(session);
      return ApiSuccess(session);
    } on AuthGatewayException catch (e) {
      return ApiFailure(FirebaseAuthErrors.map(e));
    }
  }

  Future<void> _syncSession(FirebaseAuthUserSnapshot? user) async {
    if (user == null) {
      await _sessions?.clearSession();
      await _tokens?.clearTokens();
      return;
    }
    await _sessionFromUser(user);
  }
}
