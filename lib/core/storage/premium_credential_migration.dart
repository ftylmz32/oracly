/// One-time migration of legacy plaintext Premium credentials.
library;

import '../data/datasources/local_storage.dart';
import '../data/repositories/mock_premium_repository.dart';
import 'premium_credential_keys.dart';
import 'secure_storage.dart';

abstract final class PremiumCredentialMigration {
  PremiumCredentialMigration._();

  static const doneKey = 'or_premium_credentials_migrated_v1';

  static Future<void> migrateIfNeeded(
    LocalStorage prefs,
    SecureStorage secure,
  ) async {
    if (prefs.getBool(doneKey) == true) {
      await _removeLegacyPrefKeys(prefs);
      return;
    }

    final legacyToken = prefs.getString(MockPremiumRepository.purchaseTokenKey);
    final legacyTxn = prefs.getString(MockPremiumRepository.transactionIdKey);

    if (legacyToken != null && legacyToken.isNotEmpty) {
      final existing = await secure.read(PremiumCredentialKeys.purchaseToken);
      if (existing == null || existing.isEmpty) {
        await secure.write(PremiumCredentialKeys.purchaseToken, legacyToken);
        final verify = await secure.read(PremiumCredentialKeys.purchaseToken);
        if (verify != legacyToken) return;
      }
    }

    if (legacyTxn != null && legacyTxn.trim().isNotEmpty) {
      final existing = await secure.read(PremiumCredentialKeys.transactionId);
      if (existing == null || existing.isEmpty) {
        await secure.write(PremiumCredentialKeys.transactionId, legacyTxn);
        final verify = await secure.read(PremiumCredentialKeys.transactionId);
        if (verify != legacyTxn) return;
      }
    }

    await _removeLegacyPrefKeys(prefs);
    await prefs.setBool(doneKey, true);
  }

  static Future<void> _removeLegacyPrefKeys(LocalStorage prefs) async {
    for (final key in MockPremiumRepository.legacyCredentialPrefKeys) {
      await prefs.remove(key);
    }
  }
}
