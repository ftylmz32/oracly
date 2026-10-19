/// Speech right for one delivered reply. Never a process-wide last message.
library;

abstract final class OrSpeechGrant {
  OrSpeechGrant._();

  static const metadataKey = 'speechGrant';

  static String? read(String? id) {
    final trimmed = id?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  static String? of(Map<String, String>? metadata) => read(metadata?[metadataKey]);
}
