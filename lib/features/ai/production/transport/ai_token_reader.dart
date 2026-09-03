/// Token suppliers for proxy transport — supports one forced refresh retry.
library;

typedef AiTokenReader = Future<String?> Function({bool forceRefresh});