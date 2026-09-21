/// Provider-neutral snapshot of a Firebase Auth user. Never a JWT claim dump.
library;

import '../models/account_reauth_method.dart';

class FirebaseAuthUserSnapshot {
  const FirebaseAuthUserSnapshot({
    required this.uid,
    this.email,
    this.displayName,
    this.isAnonymous = false,
    this.providerIds = const [],
  });

  final String uid;
  final String? email;
  final String? displayName;
  final bool isAnonymous;

  /// Firebase `UserInfo.providerId` values (e.g. `google.com`, `password`).
  final List<String> providerIds;

  List<AccountReauthMethod> get reauthMethods =>
      AccountReauthMethodResolver.fromProviderIds(providerIds);
}
