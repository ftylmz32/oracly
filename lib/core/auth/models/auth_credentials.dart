/// OR-1130 — Credential payloads for auth providers.
library;

import 'auth_session.dart';

class EmailCredentials {
  const EmailCredentials({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;
}

class OAuthCredentials {
  const OAuthCredentials({
    required this.idToken,
    this.accessToken,
  });

  final String idToken;
  final String? accessToken;
}

/// A fresh credential proving the CURRENT linked user's identity again —
/// never a sign-in as a different user. Required before any destructive
/// account action (deletion) for a non-anonymous user; never needed for an
/// anonymous one.
///
/// Google/Apple may use the native Firebase provider reauth flow
/// (`reauthenticateWithProvider`) when [oauth] is null — the app does not
/// need a separate Google/Apple Sign-In SDK to acquire tokens manually.
class AccountReauthCredentials {
  const AccountReauthCredentials.google([OAuthCredentials? credentials])
      : provider = AuthProviderKind.google,
        oauth = credentials,
        email = null;

  const AccountReauthCredentials.apple([OAuthCredentials? credentials])
      : provider = AuthProviderKind.apple,
        oauth = credentials,
        email = null;

  const AccountReauthCredentials.email(EmailCredentials credentials)
      : provider = AuthProviderKind.email,
        oauth = null,
        email = credentials;

  final AuthProviderKind provider;
  final OAuthCredentials? oauth;
  final EmailCredentials? email;

  /// True when Google/Apple should use Firebase's native provider UI.
  bool get usesNativeProviderFlow =>
      (provider == AuthProviderKind.google ||
          provider == AuthProviderKind.apple) &&
      oauth == null;
}
