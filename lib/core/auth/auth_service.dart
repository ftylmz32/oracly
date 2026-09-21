/// OR-1130 — Authentication service contract.
library;

import '../network/api_result.dart';
import 'models/account_reauth_method.dart';
import 'models/auth_credentials.dart';
import 'models/auth_session.dart';

abstract class AuthService {
  /// False when production has no real identity provider configured.
  bool get isConfigured;

  Future<ApiResult<AuthSession>> signInAnonymously();
  Future<ApiResult<AuthSession>> signInWithGoogle(OAuthCredentials credentials);
  Future<ApiResult<AuthSession>> signInWithApple(OAuthCredentials credentials);
  Future<ApiResult<AuthSession>> signInWithEmail(EmailCredentials credentials);
  Future<ApiResult<AuthSession>> createGuestSession();
  Future<ApiResult<AuthSession>> refreshSession();

  /// Reuse the current Firebase user, or sign in anonymously when none exists.
  Future<ApiResult<AuthSession>> ensureAnonymousSession();

  Future<ApiResult<bool>> signOut();

  /// Deletes the identity provider account. Does not wipe local data —
  /// callers must run [AccountDeletionService] so wipe happens only after
  /// remote success. Never reports success for logout-only.
  Future<ApiResult<bool>> deleteAccount();

  /// True when the current identity has no linked credential (anonymous) —
  /// deletion needs no reauthentication. False for a linked (Google/Apple/
  /// email) user, for whom [reauthenticate] must succeed before any
  /// destructive account action.
  bool get isCurrentUserAnonymous;

  /// True when Firebase currently holds a signed-in user (any kind).
  bool get hasCurrentIdentity;

  /// Live Firebase / provider uid for the current identity — never email.
  /// Null when no identity is signed in.
  String? get currentUserId;

  /// Linked reauth methods for the current user (empty when anonymous/none).
  List<AccountReauthMethod> get currentReauthMethods;

  /// Email for password reauth UI — null when unavailable.
  String? get currentUserEmail;

  /// Re-proves the CURRENT linked user's identity with a fresh credential
  /// from the same provider. Never signs in as a different user, never
  /// fabricates success.
  Future<ApiResult<bool>> reauthenticate(AccountReauthCredentials credentials);
}
