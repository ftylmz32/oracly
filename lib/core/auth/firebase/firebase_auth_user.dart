/// Provider-neutral snapshot of a Firebase Auth user. Never a JWT claim dump.
library;

class FirebaseAuthUserSnapshot {
  const FirebaseAuthUserSnapshot({
    required this.uid,
    this.email,
    this.displayName,
    this.isAnonymous = false,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final bool isAnonymous;
}
