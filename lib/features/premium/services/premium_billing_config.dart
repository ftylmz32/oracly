/// Resolves optional remote billing verify URL — never invents credentials.
library;

import '../../../core/config/oracly_runtime_config.dart';

abstract final class PremiumBillingConfig {
  PremiumBillingConfig._();

  /// Explicit only: --dart-define=ORACLY_BILLING_VERIFY_URL= or dotenv.
  /// Empty / invalid release URL → [LocalCacheEntitlementVerifier].
  /// Never silently uses localhost or plain HTTP in release.
  static String? resolveVerifyUrl({bool? releaseLocked}) {
    return OraclyRuntimeConfig.resolve(releaseLocked: releaseLocked)
        .billingVerifyUrl;
  }
}