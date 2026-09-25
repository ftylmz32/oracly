/// Provider-safe Whole Sign house fact — full scope only.
library;

final class YildiznameHouseFact {
  const YildiznameHouseFact({
    required this.factRef,
    required this.number,
    required this.sign,
  });

  final String factRef;
  final int number;
  final String sign;

  Map<String, dynamic> toProviderJson() => {
        'factRef': factRef,
        'number': number,
        'sign': sign,
      };
}
