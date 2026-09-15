/// Maps an internal Premium entitlement/verification reason code to safe,
/// natural, localized user copy. The backend/reconciler `message` field is
/// a diagnostic string (e.g. `network_or_parse`, `http_503`,
/// `verification_failed`) meant for logs, never for display — this is the
/// one place that translates it, so raw internal codes never reach the UI.
library;

import 'premium_copy.dart';

abstract final class PremiumEntitlementMessage {
  PremiumEntitlementMessage._();

  static const _networkLike = {
    'network_or_parse',
    'invalid_response',
    'entitlement_binding_unavailable',
    'provider_not_configured',
    'verification_failed',
  };

  static const _missingCredentials = {'missing_purchase_credentials'};
  static const _boundOtherAccount = {'purchase_bound_to_other_account'};

  /// [fallback] is the safe copy to show when [reason] is null, empty, or
  /// not one of the specifically-handled internal codes below — including
  /// any future/unrecognized backend reason string.
  static String forReason(String? reason, {required String fallback}) {
    final value = reason?.trim() ?? '';
    if (value.isEmpty) return fallback;
    if (value.startsWith('http_') || _networkLike.contains(value)) {
      return PremiumCopy.entitlementNetworkError;
    }
    if (_boundOtherAccount.contains(value)) {
      return PremiumCopy.entitlementBoundOtherAccount;
    }
    if (_missingCredentials.contains(value)) {
      return PremiumCopy.entitlementMissingCredentials;
    }
    // Anything already-localized (a real sentence, e.g. from
    // PremiumPurchaseResult's own copy-backed factories) passes through
    // unchanged. Internal reason codes are snake_case tokens with no
    // spaces/punctuation — never let one of those reach the UI.
    if (_looksLikeInternalCode(value)) return fallback;
    return value;
  }

  static bool _looksLikeInternalCode(String value) {
    return !value.contains(' ') && RegExp(r'^[a-z0-9_]+$').hasMatch(value);
  }
}
