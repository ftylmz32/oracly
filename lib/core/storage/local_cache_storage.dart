/// OR-1130 — JSON document cache backed by LocalStorage.
library;

import 'dart:convert';

import '../data/datasources/local_storage.dart';
import 'cache_storage.dart';

class LocalCacheStorage implements CacheStorage {
  LocalCacheStorage(this._localStorage, {String? namespace})
      : _prefix = namespace ?? 'cache_';

  final LocalStorage _localStorage;
  final String _prefix;

  String _key(String key) => '$_prefix$key';

  @override
  Future<T?> get<T>(
    String key,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final raw = _localStorage.getString(_key(key));
    if (raw == null) return null;
    return fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> set<T>(
    String key,
    T value,
    Map<String, dynamic> Function(T) toJson,
  ) async {
    await _localStorage.setString(_key(key), jsonEncode(toJson(value)));
  }

  @override
  Future<void> remove(String key) => _localStorage.remove(_key(key));

  @override
  Future<void> clear() async {
    // Production: iterate known cache keys via registry.
  }

  @override
  Future<bool> contains(String key) async {
    return _localStorage.getString(_key(key)) != null;
  }
}
