/// Exact portrait reuse guard. Compares hashes, never image bytes.
library;

import 'dart:convert';

class SoulMatePortraitGuard {
  const SoulMatePortraitGuard();

  static const maxImageCalls = 2;

  /// Same owner may reopen. A different owner must never inherit the bytes.
  bool accepts({
    required String contentHash,
    required String ownerId,
    required Map<String, String> knownOwners,
  }) {
    final hash = contentHash.trim();
    final owner = ownerId.trim();
    if (hash.isEmpty || owner.isEmpty) return true;
    final known = knownOwners[hash];
    if (known == null || known.isEmpty) return true;
    return known == owner;
  }

  Map<String, String> remember({
    required String contentHash,
    required String ownerId,
    required Map<String, String> knownOwners,
  }) {
    if (!accepts(
      contentHash: contentHash,
      ownerId: ownerId,
      knownOwners: knownOwners,
    )) {
      return knownOwners;
    }
    return {...knownOwners, contentHash: ownerId};
  }
}

Map<String, String> hashOwnersFromJson(String raw) {
  try {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return {};
    return decoded.map((key, value) => MapEntry('$key', '$value'));
  } catch (_) {
    return {};
  }
}

String hashOwnersToJson(Map<String, String> owners) => jsonEncode(owners);
