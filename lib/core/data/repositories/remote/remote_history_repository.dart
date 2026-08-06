/// OR-1130 — Remote readings repository with offline fallback.
library;

import '../../../api/api_endpoints.dart';
import '../../../domain/models/reading.dart';
import '../../../domain/repositories/history_repository.dart';
import '../../../sync/models/sync_queue_item.dart';
import 'remote_repository_base.dart';

class RemoteHistoryRepository implements HistoryRepository {
  RemoteHistoryRepository({
    required this.local,
    required this.base,
  });

  final HistoryRepository local;
  final RemoteRepositoryBase base;

  @override
  Future<List<ReadingModel>> getReadings() async {
    final remote = await base.apiClient.get<List<dynamic>>(
      ApiEndpoints.readings,
      parser: (json) => json as List<dynamic>,
    );
    final parsed = await base.unwrap(remote);
    if (parsed != null) {
      return parsed
          .map((e) => ReadingModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    return local.getReadings();
  }

  @override
  Future<void> saveReading(ReadingModel reading) async {
    await local.saveReading(reading);
    await base.enqueueSync(
      entityType: SyncEntityType.reading,
      operation: SyncOperationKind.create,
      id: reading.id,
      payload: reading.toJson(),
    );
  }

  @override
  Future<void> deleteReading(String id) async {
    await local.deleteReading(id);
    await base.enqueueSync(
      entityType: SyncEntityType.reading,
      operation: SyncOperationKind.delete,
      id: id,
      payload: {'id': id},
    );
  }

  @override
  Future<void> clearAll() => local.clearAll();
}
