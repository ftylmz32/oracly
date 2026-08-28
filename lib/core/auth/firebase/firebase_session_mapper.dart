/// Maps a Firebase user + ID token onto [AuthSession]. Does not decode JWT.
library;

import '../models/auth_session.dart';
import 'firebase_auth_user.dart';

abstract final class FirebaseSessionMapper {
  FirebaseSessionMapper._();

  static AuthSession fromUser({
    required FirebaseAuthUserSnapshot user,
    required String idToken,
    AuthProviderKind provider = AuthProviderKind.anonymous,
  }) {
    return AuthSession(
      userId: user.uid,
      provider: user.isAnonymous ? AuthProviderKind.anonymous : provider,
      accessToken: idToken,
      refreshToken: '',
      expiresAt: DateTime.now().add(const Duration(hours: 1)),
      email: user.email,
      displayName: user.displayName,
      isGuest: user.isAnonymous,
    );
  }
}
