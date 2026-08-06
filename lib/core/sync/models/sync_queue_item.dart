/// OR-1130 — Sync queue item model.
library;

enum SyncOperationKind { create, update, delete }

enum SyncEntityType {
  user,
  tarot,
  reading,
  dream,
  astrology,
  dailyEnergy,
  aiConversation,
  achievement,
  premium,
  settings,
}

class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.entityType,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  final String id;
  final SyncEntityType entityType;
  final SyncOperationKind operation;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  SyncQueueItem copyWith({
    int? retryCount,
    String? lastError,
  }) {
    return SyncQueueItem(
      id: id,
      entityType: entityType,
      operation: operation,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'entityType': entityType.name,
        'operation': operation.name,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'retryCount': retryCount,
        'lastError': lastError,
      };
}
