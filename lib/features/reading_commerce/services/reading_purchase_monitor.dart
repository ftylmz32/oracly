/// Keeps unfinished store purchases until the server grants them.
library;

import 'dart:async';

import 'reading_purchase_tracker.dart';

class ReadingPurchaseMonitor {
  ReadingPurchaseMonitor({
    required this.tracker,
    required this.updates,
    required this.buyProduct,
    required this.storePrices,
    this.buyTimeout = const Duration(seconds: 120),
    this.storeUnfinished,
  });

  /// Unfinished purchases the store still holds, read once at start: a
  /// purchase whose local record was wiped is routed to its owner again.
  final Future<List<ReadingPurchaseUpdate>> Function()? storeUnfinished;

  final ReadingPurchaseTracker tracker;
  final Future<bool> Function(String productId) buyProduct;
  final Future<Map<String, String>> Function() storePrices;
  final Duration buyTimeout;
  final Stream<List<ReadingPurchaseUpdate>> updates;
  final List<void Function(ReadingBuyKind kind, String productId)> _listeners = [];
  final List<void Function(ReadingBuyKind kind, String productId)> _waiters = [];
  StreamSubscription<List<ReadingPurchaseUpdate>>? _subscription;

  void addListener(void Function(ReadingBuyKind kind, String productId) listener) {
    _listeners.add(listener);
  }

  void removeListener(void Function(ReadingBuyKind kind, String productId) listener) {
    _listeners.remove(listener);
  }

  Future<void> start() async {
    try {
      await tracker.resume();
      _subscription ??= updates.listen((purchases) async {
        for (final purchase in purchases) {
          final kind = await tracker.accept(purchase);
          _emit(kind, purchase.productId);
        }
      });
      for (final purchase in await storeUnfinished?.call() ?? const <ReadingPurchaseUpdate>[]) {
        final kind = await tracker.accept(purchase);
        _emit(kind, purchase.productId);
      }
    } catch (_) {}
  }

  Future<ReadingBuyKind> buy(String productId) async {
    final pending = Completer<ReadingBuyKind>();
    void wait(ReadingBuyKind kind, String id) {
      if (id != productId || pending.isCompleted) return;
      if (kind == ReadingBuyKind.pending) {
        pending.complete(kind);
        return;
      }
      pending.complete(kind);
    }

    _waiters.add(wait);
    try {
      final started = await buyProduct(productId);
      if (!started) return ReadingBuyKind.failed;
      return await pending.future.timeout(
        buyTimeout,
        onTimeout: () => ReadingBuyKind.pending,
      );
    } finally {
      _waiters.remove(wait);
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  void _emit(ReadingBuyKind kind, String productId) {
    for (final listener in [..._listeners, ..._waiters]) {
      listener(kind, productId);
    }
  }
}
