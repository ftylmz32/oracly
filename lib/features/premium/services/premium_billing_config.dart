/// Resolves optional remote billing verify URL — never invents credentials.
library;

import 'package:flutter_dotenv/flutter_dotenv.dart';

abstract final class PremiumBillingConfig {
  PremiumBillingConfig._();

  /// Explicit only: --dart-define=ORACLY_BILLING_VERIFY_URL= or dotenv.
  /// Empty means [LocalCacheEntitlementVerifier] — no fake production security.
  static String? resolveVerifyUrl() {
    const define = String.fromEnvironment('ORACLY_BILLING_VERIFY_URL');
    Map<String, String> env = const {};
    try {
      env = dotenv.env;
    } catch (_) {}
    for (final raw in [define, env['ORACLY_BILLING_VERIFY_URL']]) {
      final trimmed = raw?.trim() ?? '';
      if (trimmed.isNotEmpty) return trimmed;
    }
    return null;
  }
}
