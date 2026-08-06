/// OR-1130 — Background sync orchestrator.
library;

import '../config/app_config.dart';
import '../logging/logger.dart';
import '../network/api_client.dart';
import '../api/api_endpoints.dart';
import 'retry_queue.dart';
import 'sync_queue.dart';

abstract class BackgroundSyncService {
  Future<void> start();
  Future<void> stop();
  Future<void> syncNow();
}

class BackgroundSyncCoordinator implements BackgroundSyncService {
  BackgroundSyncCoordinator({
    required this.syncQueue,
    required this.retryQueue,
    required this.apiClient,
    Logger? logger,
  }) : _logger = logger ?? Logger('BackgroundSync');

  final SyncQueue syncQueue;
  final RetryQueue retryQueue;
  final ApiClient apiClient;
  final Logger _logger;
  bool _running = false;

  @override
  Future<void> start() async {
    _running = true;
    _logger.info('Background sync started');
  }

  @override
  Future<void> stop() async {
    _running = false;
    _logger.info('Background sync stopped');
  }

  @override
  Future<void> syncNow() async {
    if (!_running) return;

    final item = await retryQueue.nextRetryable();
    if (item == null) return;

    _logger.debug('Syncing ${item.entityType.name}/${item.id}');

    final result = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.syncPush,
      body: item.toJson(),
      parser: (json) => json as Map<String, dynamic>,
    );

    await result.when(
      success: (_) async {
        await syncQueue.dequeue(item.id);
      },
      failure: (error) async {
        await syncQueue.markFailed(item.id, error.message);
        await retryQueue.scheduleRetry(item);
      },
    );
  }

  Duration get interval => Duration(
        seconds: AppConfig.isInitialized
            ? AppConfig.instance.syncIntervalSeconds
            : 300,
      );
}
