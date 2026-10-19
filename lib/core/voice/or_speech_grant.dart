/// Last server speech grant for this process. Not a premium proof.
library;

abstract final class OrSpeechGrant {
  OrSpeechGrant._();

  static String? current;

  static void remember(String? id) {
    final trimmed = id?.trim() ?? '';
    if (trimmed.isEmpty) return;
    current = trimmed;
  }

  static void clear() => current = null;
}
