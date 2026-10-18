import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/universe/oracly_universe_layer.dart';

import 'home_daypart_probe.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final width in const <double>[320, 360, 390, 412]) {
    testWidgets('greeting and trace hold $width at 1.3 text', (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final size = Size(width, 800);
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: const TextScaler.linear(1.3),
              devicePixelRatio: 3,
            ),
            child: OraclyUniverseTicker(
              now: () => DateTime(2026, 6, 15, 8),
              child: const DaypartProbe(traceHeight: 118),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('İyi sabahlar'), findsOneWidget);
      expect(find.text('Sabah'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
