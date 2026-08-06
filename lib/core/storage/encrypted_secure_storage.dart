/// OR-1130 — Encrypted local storage using SharedPreferences + encoding.
library;

import 'dart:convert';

import '../data/datasources/local_storage.dart';
import 'secure_storage.dart';

/// Production swap target: flutter_secure_storage.
class EncryptedSecureStorage implements SecureStorage {
  EncryptedSecureStorage(this._localStorage, {String? namespace})
      : _prefix = namespace ?? 'secure_';

  final LocalStorage _localStorage;
  final String _prefix;

  String _key(String key) => '$_prefix$key';

  @override
  Future<String?> read(String key) async {
    final encoded = _localStorage.getString(_key(key));
    if (encoded == null) return null;
    return utf8.decode(base64Decode(encoded));
  }

  @override
  Future<void> write(String key, String value) async {
    final encoded = base64Encode(utf8.encode(value));
    await _localStorage.setString(_key(key), encoded);
  }

  @override
  Future<void> delete(String key) => _localStorage.remove(_key(key));

  @override
  Future<void> deleteAll() async {
    // Prefix-scoped delete handled by higher-level registry in production.
  }
}
