/// Runs secure-storage migrations once per install.
library;

import '../data/datasources/local_storage.dart';
import 'legacy_secure_storage_migration.dart';
import 'premium_credential_migration.dart';
import 'secure_storage.dart';

abstract final class SecureStorageBootstrap {
  SecureStorageBootstrap._();

  static Future<void> run(LocalStorage prefs, SecureStorage secure) async {
    await LegacySecureStorageMigration.runIfNeeded(prefs, secure);
    await PremiumCredentialMigration.migrateIfNeeded(prefs, secure);
  }
}
