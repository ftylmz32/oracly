import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/evrenim/domain/evrenim_constellation_layout.dart';

void main() {
  group('EvrenimConstellationLayout', () {
    test('same persisted reading stays at the same position', () {
      final a = EvrenimConstellationLayout.forReading(
        kind: 'coffee', id: 'reading-1',
      );
      final b = EvrenimConstellationLayout.forReading(
        kind: 'coffee', id: 'reading-1',
      );
      expect(a.x, b.x);
      expect(a.y, b.y);
    });

    test('coordinates are finite and remain within viewport', () {
      for (var i = 0; i < 1000; i++) {
        final p = EvrenimConstellationLayout.forReading(
          kind: i.isEven ? 'coffee' : 'tarot',
          id: 'reading-$i',
        );
        expect(p.x.isFinite && p.y.isFinite, isTrue);
        expect(p.x, inInclusiveRange(0.0, 1.0));
        expect(p.y, inInclusiveRange(0.0, 1.0));
      }
    });

    test('same ID across kinds is not the same star', () {
      final a = EvrenimConstellationLayout.forReading(
        kind: 'coffee', id: 'same',
      );
      final b = EvrenimConstellationLayout.forReading(
        kind: 'tarot', id: 'same',
      );
      expect(a.x != b.x || a.y != b.y, isTrue);
    });
  });
}
