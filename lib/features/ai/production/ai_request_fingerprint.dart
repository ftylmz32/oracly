/// Compact fingerprints — never hash full image payloads.
library;

abstract final class AiRequestFingerprint {
  AiRequestFingerprint._();

  static String text(String op, String value) =>
      '$op:${value.trim().toLowerCase()}';

  static String image(String op, List<int> bytes, [String extra = '']) {
    if (bytes.isEmpty) return '$op:0:$extra';
    final mid = bytes[bytes.length >> 1];
    return '$op:${bytes.length}:${bytes.first}:$mid:${bytes.last}:$extra';
  }

  static String soulMate({
    required String name,
    required String birthDate,
    String? gender,
    String? intention,
  }) {
    return text(
      'soulmate',
      '$name|$birthDate|${gender ?? ''}|${intention ?? ''}',
    );
  }

  static String idempotencyKey(String fingerprint) {
    final hash = fingerprint.hashCode.toUnsigned(32).toRadixString(16);
    return 'or-$hash';
  }
}
