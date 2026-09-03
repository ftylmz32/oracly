/// OR-1130 — Deprecated base64 SharedPreferences shim (non-cryptographic).
///
/// Replaced by [PlatformSecureStorage]. Retained only for reference during
/// migration; do not wire in production providers.
library;

import 'dart:convert';

import '../data/datasources/local_storage.dart';
import 'secure_storage.dart';

@Deprecated('Use PlatformSecureStorage via secureStorageProvider')
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
    for (final key in _localStorage.keys
        .where((k) => k.startsWith(_prefix))
        .toList()) {
      await _localStorage.remove(key);
    }
  }
}
