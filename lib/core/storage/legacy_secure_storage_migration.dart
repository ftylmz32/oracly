/// One-time migration from base64 SharedPreferences secure_* entries.
library;

import 'dart:convert';

import '../data/datasources/local_storage.dart';
import 'secure_storage.dart';

abstract final class LegacySecureStorageMigration {
  LegacySecureStorageMigration._();

  static const _legacyPrefix = 'secure_';
  static const _doneKey = 'or_secure_storage_migrated_v1';

  static Future<void> runIfNeeded(
    LocalStorage prefs,
    SecureStorage secure,
  ) async {
    if (prefs.getBool(_doneKey) == true) return;
    await _migrateLegacyEntries(prefs, secure);
    await prefs.setBool(_doneKey, true);
  }

  static Future<void> _migrateLegacyEntries(
    LocalStorage prefs,
    SecureStorage secure,
  ) async {
    for (final key in prefs.keys.where((k) => k.startsWith(_legacyPrefix))) {
      final encoded = prefs.getString(key);
      if (encoded == null) {
        await prefs.remove(key);
        continue;
      }
      final logical = key.substring(_legacyPrefix.length);
      try {
        final value = utf8.decode(base64Decode(encoded));
        if (value.isNotEmpty) {
          await secure.write(logical, value);
        }
      } catch (_) {
        // Drop corrupt legacy material.
      }
      await prefs.remove(key);
    }
  }
}
