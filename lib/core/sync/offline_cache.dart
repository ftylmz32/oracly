/// OR-1130 — Offline cache coordinator.
library;

import '../storage/cache_storage.dart';

abstract class OfflineCache {
  Future<T?> read<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  );
  Future<void> write<T>(
    String key,
    T value,
    Map<String, dynamic> Function(T) toJson,
  );
  Future<void> invalidate(String key);
}

class OfflineCacheManager implements OfflineCache {
  OfflineCacheManager(this._cache);

  final CacheStorage _cache;

  @override
  Future<T?> read<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) =>
      _cache.get(key, fromJson);

  @override
  Future<void> write<T>(
    String key,
    T value,
    Map<String, dynamic> Function(T) toJson,
  ) =>
      _cache.set(key, value, toJson);

  @override
  Future<void> invalidate(String key) => _cache.remove(key);
}
