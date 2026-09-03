/// Resolves entitlement verifier — remote URL or honest local cache.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../services/http_billing_entitlement_verifier.dart';
import '../services/local_cache_entitlement_verifier.dart';
import '../services/premium_billing_config.dart';
import '../services/premium_entitlement_verifier.dart';

final premiumEntitlementVerifierProvider =
    Provider<PremiumEntitlementVerifier>((ref) {
  final url = PremiumBillingConfig.resolveVerifyUrl();
  if (url != null && url.isNotEmpty) {
    final tokenManager = ref.watch(tokenManagerProvider);
    return HttpBillingEntitlementVerifier(
      verifyUrl: url,
      accessTokenProvider: tokenManager.getAccessToken,
    );
  }
  return const LocalCacheEntitlementVerifier();
});
