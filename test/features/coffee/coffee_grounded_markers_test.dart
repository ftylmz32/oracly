/// Coffee grounded markers — real coords only, never invented.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/coffee/models/coffee_symbol.dart';
import 'package:oracly_new/features/coffee/models/coffee_symbol_focus.dart';
import 'package:oracly_new/features/coffee/presentation/reference/coffee_result_markers.dart';

void main() {
  test('focus rejects missing and whole-frame boxes', () {
    expect(CoffeeSymbolFocus.tryParse(const {}), isNull);
    expect(
      CoffeeSymbolFocus.tryParse({
        'bbox': [0.0, 0.0, 0.95, 0.95],
      }),
      isNull,
    );
    expect(
      CoffeeSymbolFocus.tryParse({
        'focus': {'x': 0.2, 'y': 0.3, 'w': 0.18, 'h': 0.16},
      }),
      isNotNull,
    );
  });

  test('grounded marks ignore symbols without reliable coords', () {
    final marks = CoffeeGroundedMarks.from(const [
      CoffeeSymbol(
        name: 'Kuş',
        meaning: 'haber',
        interpretation: 'Hafif bir haber.',
        trust: CoffeeMarkTrust.high,
      ),
      CoffeeSymbol(
        name: 'Yol',
        meaning: 'yolculuk',
        interpretation: 'Bir geçiş.',
        trust: CoffeeMarkTrust.high,
        focus: CoffeeSymbolFocus(x: 0.4, y: 0.5, w: 0.2, h: 0.15),
      ),
    ]);
    expect(marks, hasLength(1));
    expect(marks.first.index, 1);
    expect(marks.first.label, 'Yol');
  });

  test('parser keeps focus from JSON when reliable', () {
    final symbol = CoffeeSymbol.fromJson({
      'ad': 'Kalp',
      'anlam': 'yakınlık',
      'yorum': 'Sıcak bir bağ.',
      'güven': 'yüksek',
      'bbox': [0.12, 0.22, 0.2, 0.18],
    });
    expect(symbol.hasGroundedMarker, isTrue);
    expect(symbol.focus!.x, 0.12);
  });
}
