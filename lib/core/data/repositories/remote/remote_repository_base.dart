/// OR-1130 — Remote API repository base helpers.
library;

import '../../../network/api_client.dart';
import '../../../network/api_result.dart';
import '../../../sync/models/sync_queue_item.dart';
import '../../../sync/sync_queue.dart';

abstract class RemoteRepositoryBase {
  RemoteRepositoryBase({
    required this.apiClient,
    required this.syncQueue,
  });

  final ApiClient apiClient;
  final SyncQueue syncQueue;

  Future<void> enqueueSync({
    required SyncEntityType entityType,
    required SyncOperationKind operation,
    required String id,
    required Map<String, dynamic> payload,
  }) {
    return syncQueue.enqueue(
      SyncQueueItem(
        id: id,
        entityType: entityType,
        operation: operation,
        payload: payload,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<T?> unwrap<T>(ApiResult<T> result) async {
    return result.when(
      success: (data) => data,
      failure: (_) => null,
    );
  }
}
