/// OR-1130 — Auth session model.
library;

enum AuthProviderKind {
  anonymous,
  google,
  apple,
  email,
  guest,
}

class AuthSession {
  const AuthSession({
    required this.userId,
    required this.provider,
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.email,
    this.displayName,
    this.isGuest = false,
  });

  final String userId;
  final AuthProviderKind provider;
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final String? email;
  final String? displayName;
  final bool isGuest;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? email,
    String? displayName,
  }) {
    return AuthSession(
      userId: userId,
      provider: provider,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      isGuest: isGuest,
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'provider': provider.name,
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'expiresAt': expiresAt.toIso8601String(),
        'email': email,
        'displayName': displayName,
        'isGuest': isGuest,
      };

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    return AuthSession(
      userId: json['userId'] as String,
      provider: AuthProviderKind.values.byName(json['provider'] as String),
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      isGuest: json['isGuest'] as bool? ?? false,
    );
  }
}
