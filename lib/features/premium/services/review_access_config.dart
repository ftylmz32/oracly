/// Resolves the review-access activate URL from the same backend host as
/// billing verification — never a separate invented host, never a new
/// mandatory release key. Unconfigured billing means unconfigured review
/// access too.
library;

import 'premium_billing_config.dart';

abstract final class ReviewAccessConfig {
  ReviewAccessConfig._();

  static String? resolveActivateUrl({bool? releaseLocked}) {
    final billingUrl =
        PremiumBillingConfig.resolveVerifyUrl(releaseLocked: releaseLocked);
    if (billingUrl == null || billingUrl.isEmpty) return null;
    final uri = Uri.tryParse(billingUrl);
    if (uri == null) return null;
    return uri.replace(path: '/v1/review-access/activate').toString();
  }
}
