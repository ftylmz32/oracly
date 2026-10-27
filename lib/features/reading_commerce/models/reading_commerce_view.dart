/// What the purchase screen may show. A missing store price hides that buy.
library;

enum ReadingCommerceFocus { all, coffee, palm }

class ReadingCommerceView {
  const ReadingCommerceView({
    required this.coffeeCredits,
    required this.palmCredits,
    this.coffeePrice,
    this.palmPrice,
    this.packPrice,
    this.message,
    this.billingQa = false,
  });

  final int coffeeCredits;
  final int palmCredits;
  final String? coffeePrice;
  final String? palmPrice;
  final String? packPrice;
  final String? message;
  final bool billingQa;

  bool get showCoffee => coffeePrice != null;
  bool get showPalm => palmPrice != null;
  bool get showPack => packPrice != null;

  static const coffeeId = 'app.oracly.reading.coffee';
  static const palmId = 'app.oracly.reading.palm';
  static const packId = 'app.oracly.reading.coffee.pack3';

  factory ReadingCommerceView.closed() =>
      const ReadingCommerceView(coffeeCredits: 0, palmCredits: 0);

  factory ReadingCommerceView.decide({
    required bool commerceOpen,
    required bool purchasable,
    required bool platformAdmitted,
    required Map<String, String> storePrices,
    required int coffeeCredits,
    required int palmCredits,
    String? message,
    bool billingQa = false,
  }) {
    final offered = commerceOpen && purchasable && platformAdmitted;
    String? price(String id) {
      if (!offered) return null;
      final label = storePrices[id]?.trim();
      if (label == null || label.isEmpty) return null;
      return label;
    }

    return ReadingCommerceView(
      coffeeCredits: coffeeCredits,
      palmCredits: palmCredits,
      coffeePrice: price(coffeeId),
      palmPrice: price(palmId),
      packPrice: price(packId),
      message: message,
      billingQa: billingQa,
    );
  }
}
