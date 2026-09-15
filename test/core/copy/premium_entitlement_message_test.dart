/// Internal Premium verification reason codes must never reach the UI
/// verbatim — only safe, natural, localized copy.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/copy/premium_entitlement_message.dart';

void main() {
  group('PremiumEntitlementMessage.forReason', () {
    const fallback = 'FALLBACK_COPY';

    test('maps known network/transient reason codes to localized copy, '
        'never the raw code', () {
      for (final reason in [
        'network_or_parse',
        'invalid_response',
        'http_503',
        'http_500',
        'entitlement_binding_unavailable',
        'provider_not_configured',
        'verification_failed',
      ]) {
        final mapped = PremiumEntitlementMessage.forReason(
          reason,
          fallback: fallback,
        );
        expect(mapped, isNot(reason), reason: 'leaked raw reason: $reason');
        expect(mapped, PremiumCopy.entitlementNetworkError);
      }
    });

    test('maps a cross-account binding denial to its own honest copy', () {
      final mapped = PremiumEntitlementMessage.forReason(
        'purchase_bound_to_other_account',
        fallback: fallback,
      );
      expect(mapped, isNot('purchase_bound_to_other_account'));
      expect(mapped, PremiumCopy.entitlementBoundOtherAccount);
    });

    test('maps missing purchase credentials to its own honest copy', () {
      final mapped = PremiumEntitlementMessage.forReason(
        'missing_purchase_credentials',
        fallback: fallback,
      );
      expect(mapped, isNot('missing_purchase_credentials'));
      expect(mapped, PremiumCopy.entitlementMissingCredentials);
    });

    test('an unrecognized/future internal-looking code safely falls back, '
        'never rendered verbatim', () {
      final mapped = PremiumEntitlementMessage.forReason(
        'some_future_backend_error_code',
        fallback: fallback,
      );
      expect(mapped, fallback);
      expect(mapped, isNot('some_future_backend_error_code'));
    });

    test('null or empty reason falls back safely', () {
      expect(
        PremiumEntitlementMessage.forReason(null, fallback: fallback),
        fallback,
      );
      expect(
        PremiumEntitlementMessage.forReason('', fallback: fallback),
        fallback,
      );
      expect(
        PremiumEntitlementMessage.forReason('   ', fallback: fallback),
        fallback,
      );
    });

    test('an already-localized human sentence passes through unchanged', () {
      const humanCopy = 'The purchase could not be completed.';
      expect(
        PremiumEntitlementMessage.forReason(humanCopy, fallback: fallback),
        humanCopy,
      );
    });
  });
}
