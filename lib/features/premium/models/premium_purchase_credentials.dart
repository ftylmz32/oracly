/// Store purchase evidence for verification — never log token values.
library;

class PremiumPurchaseCredentials {
  const PremiumPurchaseCredentials({
    required this.platform,
    required this.productId,
    required this.purchaseToken,
    this.transactionId,
  });

  final String platform;
  final String productId;
  final String purchaseToken;
  final String? transactionId;

  bool get isComplete =>
      platform.isNotEmpty && productId.isNotEmpty && purchaseToken.isNotEmpty;
}
