/// OR-1130 — Failed sync retry queue with backoff.
library;

import '../logging/logger.dart';
import 'models/sync_queue_item.dart';
import 'sync_queue.dart';

abstract class RetryQueue {
  Future<void> scheduleRetry(SyncQueueItem item);
  Future<SyncQueueItem?> nextRetryable();
  void clear();
}

class ExponentialRetryQueue implements RetryQueue {
  ExponentialRetryQueue(this._syncQueue, {Logger? logger})
      : _logger = logger ?? Logger('RetryQueue');

  final SyncQueue _syncQueue;
  final Logger _logger;
  final Map<String, DateTime> _nextAttempt = {};

  @override
  Future<void> scheduleRetry(SyncQueueItem item) async {
    final delay = Duration(seconds: 2 << item.retryCount.clamp(0, 5));
    _nextAttempt[item.id] = DateTime.now().add(delay);
    _logger.info('Retry scheduled for ${item.id} in ${delay.inSeconds}s');
  }

  @override
  Future<SyncQueueItem?> nextRetryable() async {
    final now = DateTime.now();
    for (final item in _syncQueue.pendingItems) {
      final next = _nextAttempt[item.id];
      if (next == null || now.isAfter(next)) return item;
    }
    return null;
  }

  @override
  void clear() => _nextAttempt.clear();
}
