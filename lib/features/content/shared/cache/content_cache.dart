/// OR-1150 — Content cache layer — database-ready abstraction.
library;

abstract class ContentCacheLayer {
  Future<T?> get<T>(String key, T Function(Map<String, dynamic> json) fromJson);
  Future<void> set<T>(
    String key,
    T value,
    Map<String, dynamic> Function(T) toJson, {
    Duration? ttl,
  });
  Future<void> invalidate(String key);
  Future<void> invalidatePrefix(String prefix);
  Future<bool> contains(String key);
}

class InMemoryContentCache implements ContentCacheLayer {
  InMemoryContentCache();

  final Map<String, _CacheEntry> _store = {};

  @override
  Future<T?> get<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final entry = _store[key];
    if (entry == null) return null;
    if (entry.expiresAt != null && DateTime.now().isAfter(entry.expiresAt!)) {
      _store.remove(key);
      return null;
    }
    return fromJson(entry.payload);
  }

  @override
  Future<void> set<T>(
    String key,
    T value,
    Map<String, dynamic> Function(T) toJson, {
    Duration? ttl,
  }) async {
    _store[key] = _CacheEntry(
      payload: toJson(value),
      expiresAt: ttl == null ? null : DateTime.now().add(ttl),
    );
  }

  @override
  Future<void> invalidate(String key) async => _store.remove(key);

  @override
  Future<void> invalidatePrefix(String prefix) async {
    _store.removeWhere((key, _) => key.startsWith(prefix));
  }

  @override
  Future<bool> contains(String key) async => _store.containsKey(key);
}

class _CacheEntry {
  _CacheEntry({required this.payload, this.expiresAt});
  final Map<String, dynamic> payload;
  final DateTime? expiresAt;
}

/// Decorator — caches repository reads with stampede protection hook point.
class CachedContentReader<T> {
  CachedContentReader({
    required this.cache,
    required this.namespace,
    required this.fromJson,
    required this.toJson,
    this.defaultTtl = const Duration(hours: 24),
  });

  final ContentCacheLayer cache;
  final String namespace;
  final T Function(Map<String, dynamic> json) fromJson;
  final Map<String, dynamic> Function(T) toJson;
  final Duration defaultTtl;

  String _key(String id) => '$namespace:$id';

  Future<T?> read(String id, Future<T?> Function() loader) async {
    final cached = await cache.get(_key(id), fromJson);
    if (cached != null) return cached;
    final fresh = await loader();
    if (fresh != null) {
      await cache.set(_key(id), fresh, toJson, ttl: defaultTtl);
    }
    return fresh;
  }

  Future<List<T>> readAll(
    String listKey,
    Future<List<T>> Function() loader,
  ) async {
    final cached = await cache.get<List<dynamic>>(
      _key(listKey),
      (json) => json['items'] as List<dynamic>,
    );
    if (cached != null) {
      return cached
          .map((e) => fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    }
    final fresh = await loader();
    await cache.set(
      _key(listKey),
      fresh,
      (items) => {
        'items': items.map(toJson).toList(),
      },
      ttl: defaultTtl,
    );
    return fresh;
  }
}
