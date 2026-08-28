/// Minted share link before the system sheet completes.
library;

class IssuedShareReference {
  const IssuedShareReference({
    required this.id,
    required this.uri,
    this.localResultKey,
  });

  final String id;
  final Uri uri;
  final String? localResultKey;
}
