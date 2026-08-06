/// OR-1130 — Offline-first sync queue.
library;

import 'dart:async';

import '../logging/logger.dart';
import 'models/sync_queue_item.dart';

abstract class SyncQueue {
  Stream<List<SyncQueueItem>> get itemsStream;
  List<SyncQueueItem> get pendingItems;
  Future<void> enqueue(SyncQueueItem item);
  Future<void> dequeue(String id);
  Future<void> markFailed(String id, String error);
}

class InMemorySyncQueue implements SyncQueue {
  InMemorySyncQueue({Logger? logger}) : _logger = logger ?? Logger('SyncQueue');

  final Logger _logger;
  final List<SyncQueueItem> _items = [];
  final _controller = StreamController<List<SyncQueueItem>>.broadcast();

  @override
  Stream<List<SyncQueueItem>> get itemsStream => _controller.stream;

  @override
  List<SyncQueueItem> get pendingItems => List.unmodifiable(_items);

  @override
  Future<void> enqueue(SyncQueueItem item) async {
    _items.add(item);
    _logger.debug('Enqueued ${item.entityType.name}/${item.id}');
    _controller.add(pendingItems);
  }

  @override
  Future<void> dequeue(String id) async {
    _items.removeWhere((e) => e.id == id);
    _controller.add(pendingItems);
  }

  @override
  Future<void> markFailed(String id, String error) async {
    final index = _items.indexWhere((e) => e.id == id);
    if (index == -1) return;
    _items[index] = _items[index].copyWith(
      retryCount: _items[index].retryCount + 1,
      lastError: error,
    );
    _controller.add(pendingItems);
  }

  void dispose() => _controller.close();
}
