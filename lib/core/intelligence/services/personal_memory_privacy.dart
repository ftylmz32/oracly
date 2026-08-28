/// Rejects raw transcripts, secrets, and oversized blobs in memory JSON.
library;

abstract final class PersonalMemoryPrivacy {
  PersonalMemoryPrivacy._();

  static const forbiddenKeys = {
    'messages',
    'messagesJson',
    'dreamText',
    'rawText',
    'transcript',
    'image',
    'imageBase64',
    'token',
    'apiKey',
    'authorization',
    'password',
  };

  static const maxJsonChars = 4000;
  static const maxFieldChars = 80;

  static bool isSafe(Map<String, dynamic> json) {
    final encoded = json.toString();
    if (encoded.length > maxJsonChars) return false;
    return !_walk(json);
  }

  static bool _walk(Object? node) {
    if (node is Map) {
      for (final entry in node.entries) {
        final key = entry.key.toString().toLowerCase();
        if (forbiddenKeys.any(key.contains)) return true;
        if (entry.value is String &&
            (entry.value as String).length > maxFieldChars &&
            key != 'fingerprint') {
          return true;
        }
        if (_walk(entry.value)) return true;
      }
    } else if (node is List) {
      for (final item in node) {
        if (_walk(item)) return true;
      }
    }
    return false;
  }
}
