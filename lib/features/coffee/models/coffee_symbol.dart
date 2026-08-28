/// One coffee-cup symbol with meaning, in-context reading, and vision trust.
library;

import 'coffee_symbol_focus.dart';

enum CoffeeMarkTrust {
  high,
  mid,
  low;

  bool get isFirm => this != CoffeeMarkTrust.low;

  static CoffeeMarkTrust parse(Object? raw) {
    final text = '$raw'.toLowerCase();
    if (text.contains('düşük') || text.contains('low')) {
      return CoffeeMarkTrust.low;
    }
    if (text.contains('orta') ||
        text.contains('mid') ||
        text.contains('medium')) {
      return CoffeeMarkTrust.mid;
    }
    return CoffeeMarkTrust.high;
  }
}

class CoffeeSymbol {
  const CoffeeSymbol({
    required this.name,
    required this.meaning,
    required this.interpretation,
    this.trust = CoffeeMarkTrust.mid,
    this.focus,
  });

  final String name;
  final String meaning;
  final String interpretation;
  final CoffeeMarkTrust trust;

  /// Real provider coords only. Null → never draw a marker.
  final CoffeeSymbolFocus? focus;

  bool get hasGroundedMarker => focus?.isReliable == true;

  Map<String, dynamic> toJson() => {
        'name': name,
        'meaning': meaning,
        'interpretation': interpretation,
        'trust': trust.name,
        if (focus != null) 'focus': focus!.toJson(),
      };

  factory CoffeeSymbol.fromJson(Map<String, dynamic> json) {
    return CoffeeSymbol(
      name: (json['name'] ?? json['ad'] ?? '') as String,
      meaning: (json['meaning'] ?? json['anlam'] ?? '') as String,
      interpretation:
          (json['interpretation'] ?? json['yorum'] ?? '') as String,
      trust: CoffeeMarkTrust.parse(
        json['güven'] ?? json['confidence'] ?? json['trust'],
      ),
      focus: CoffeeSymbolFocus.tryParse(json),
    );
  }
}
