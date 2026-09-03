/// Android Keystore / iOS Keychain-backed secure storage.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_storage.dart';

class PlatformSecureStorage implements SecureStorage {
  PlatformSecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  final FlutterSecureStorage _storage;
  static const _prefix = 'oracly.secure.';

  String _key(String key) => '$_prefix$key';

  @override
  Future<String?> read(String key) => _storage.read(key: _key(key));

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: _key(key), value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: _key(key));

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}
