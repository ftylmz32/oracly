/// OR-1130 — Typed offline cache contract.
library;

abstract class CacheStorage {
  Future<T?> get<T>(String key, T Function(Map<String, dynamic> json) fromJson);
  Future<void> set<T>(String key, T value, Map<String, dynamic> Function(T) toJson);
  Future<void> remove(String key);
  Future<void> clear();
  Future<bool> contains(String key);
}
