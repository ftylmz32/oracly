/// Provider-safe placement fact — no raw longitude, no birth data.
library;

final class YildiznamePlacementFact {
  const YildiznamePlacementFact({
    required this.factRef,
    required this.body,
    required this.sign,
    required this.certainty,
    this.degreeWithinSign,
    this.retrograde,
    this.house,
  });

  final String factRef;
  final String body;
  final String sign;
  final String certainty;
  final double? degreeWithinSign;
  final bool? retrograde;
  final int? house;

  Map<String, dynamic> toProviderJson() => {
        'factRef': factRef,
        'body': body,
        'sign': sign,
        'certainty': certainty,
        if (degreeWithinSign != null) 'degreeWithinSign': degreeWithinSign,
        if (retrograde != null) 'retrograde': retrograde,
        if (house != null) 'house': house,
      };
}
