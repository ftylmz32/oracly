/// Port for store receipt / purchase-token verification.
///
/// HONESTY: Implementing this port does not mean Apple/Google validation
/// is production-ready. A successful [PremiumVerifyStatus.active] must come
/// from a real provider check — never from a local boolean alone.
library;

import '../models/premium_verify_result.dart';

abstract class PremiumEntitlementVerifier {
  /// True when a remote billing verify URL is configured.
  /// Does **not** imply receipts are validated against Apple/Google.
  bool get isRemoteVerifierConfigured;

  Future<PremiumVerifyResult> verify({
    required String platform,
    required String productId,
    required String purchaseToken,
    String? transactionId,
  });
}
