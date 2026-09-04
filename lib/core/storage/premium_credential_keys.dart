/// Secure-storage keys for Premium purchase verification input.
library;

abstract final class PremiumCredentialKeys {
  PremiumCredentialKeys._();

  static const purchaseToken = 'premium.purchase_token';
  static const transactionId = 'premium.transaction_id';

  /// Store review-access code — distinct namespace, never mixed with real
  /// purchase credentials.
  static const reviewAccessCode = 'review_access.code';
}
