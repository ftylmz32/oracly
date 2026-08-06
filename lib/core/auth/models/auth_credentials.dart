/// OR-1130 — Credential payloads for auth providers.
library;

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
