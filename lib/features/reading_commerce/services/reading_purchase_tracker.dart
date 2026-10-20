/// Decides when a store event may become a credit. The store stream outlives one tap.
library;

enum ReadingBuyKind { granted, pending, canceled, failed }

enum ReadingVerifyOutcome { granted, rejected, unavailable }

enum ReadingPurchaseStatus { pending, purchased, canceled, failed }

class ReadingPurchaseUpdate {
  const ReadingPurchaseUpdate({
    required this.productId,
    required this.token,
    required this.purchaseId,
    required this.status,
  });

  final String productId;
  final String token;
  final String purchaseId;
  final ReadingPurchaseStatus status;
}

abstract class ReadingPurchaseMemory {
  Future<List<ReadingPurchaseUpdate>> load();
  Future<void> save(ReadingPurchaseUpdate purchase);
  Future<void> remove(String token);
}

class MemoryReadingPurchases implements ReadingPurchaseMemory {
  final List<ReadingPurchaseUpdate> items = [];

  @override
  Future<List<ReadingPurchaseUpdate>> load() async => List.of(items);

  @override
  Future<void> save(ReadingPurchaseUpdate purchase) async {
    items.removeWhere((item) => item.token == purchase.token);
    items.add(purchase);
  }

  @override
  Future<void> remove(String token) async {
    items.removeWhere((item) => item.token == token);
  }
}

class ReadingPurchaseTracker {
  ReadingPurchaseTracker({
    required this.verify,
    required this.complete,
    required this.memory,
  });

  final Future<ReadingVerifyOutcome> Function(ReadingPurchaseUpdate update) verify;
  final Future<void> Function(ReadingPurchaseUpdate update) complete;
  final ReadingPurchaseMemory memory;
  Future<void> _queue = Future<void>.value();

  Future<ReadingBuyKind> accept(ReadingPurchaseUpdate update) {
    return _serial(() => _accept(update));
  }

  Future<void> resume() {
    return _serial(() async {
      final saved = await memory.load();
      for (final purchase in saved) {
        if (purchase.status != ReadingPurchaseStatus.purchased) continue;
        await _accept(purchase);
      }
    });
  }

  Future<T> _serial<T>(Future<T> Function() work) {
    final run = _queue.then((_) => work());
    _queue = run.then((_) {}, onError: (_) {});
    return run;
  }

  Future<ReadingBuyKind> _accept(ReadingPurchaseUpdate update) async {
    if (update.status == ReadingPurchaseStatus.pending) {
      await memory.save(update);
      return ReadingBuyKind.pending;
    }
    if (update.status == ReadingPurchaseStatus.canceled) {
      await memory.remove(update.token);
      return ReadingBuyKind.canceled;
    }
    if (update.status != ReadingPurchaseStatus.purchased || update.token.trim().isEmpty) {
      return ReadingBuyKind.failed;
    }
    await memory.save(update);
    final ReadingVerifyOutcome outcome;
    try {
      outcome = await verify(update);
    } catch (_) {
      return ReadingBuyKind.failed;
    }
    if (outcome == ReadingVerifyOutcome.unavailable) return ReadingBuyKind.failed;
    if (outcome != ReadingVerifyOutcome.granted) {
      await memory.remove(update.token);
      return ReadingBuyKind.failed;
    }
    try {
      await complete(update);
      await memory.remove(update.token);
    } catch (_) {}
    return ReadingBuyKind.granted;
  }
}
