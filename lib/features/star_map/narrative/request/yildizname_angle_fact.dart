/// Provider-safe angle fact (Asc / MC) — full scope only.
library;

final class YildiznameAngleFact {
  const YildiznameAngleFact({
    required this.factRef,
    required this.kind,
    required this.sign,
    required this.certainty,
    this.degreeWithinSign,
    this.house,
  });

  final String factRef;
  final String kind;
  final String sign;
  final String certainty;
  final double? degreeWithinSign;
  final int? house;

  Map<String, dynamic> toProviderJson() => {
        'factRef': factRef,
        'kind': kind,
        'sign': sign,
        'certainty': certainty,
        if (degreeWithinSign != null) 'degreeWithinSign': degreeWithinSign,
        if (house != null) 'house': house,
      };
}
