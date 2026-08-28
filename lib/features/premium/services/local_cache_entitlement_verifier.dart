/// Default verifier — local cache is never authoritative for production Premium.
///
/// Returns [PremiumVerifyStatus.unverified] in debug and whenever no remote
/// billing provider is wired. Does **not** validate App Store / Play receipts.
/// Production payment security is **not** solved by this class.
library;

import 'package:flutter/foundation.dart';

import '../models/premium_verify_result.dart';
import 'premium_entitlement_verifier.dart';

class LocalCacheEntitlementVerifier implements PremiumEntitlementVerifier {
  const LocalCacheEntitlementVerifier();

  @override
  bool get isRemoteVerifierConfigured => false;

  @override
  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  }) async {
    // Never grant production Premium from local evidence alone.
    if (kDebugMode) {
      return PremiumVerifyResult.unverified(
        'debug_local_cache_not_authoritative',
      );
    }
    return PremiumVerifyResult.unverified('provider_not_configured');
  }
}
