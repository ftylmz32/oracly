import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/home/epic030/home_epic030_hero.dart';
import 'package:oracly_new/features/home/epic030/home_epic030_feature_grid.dart';

void main() {
  const viewports = <Size>[
    Size(360, 800),
    Size(393, 852),
    Size(412, 915),
    Size(430, 932),
  ];

  group('EPIC-030 home widgets — no overflow', () {
    for (final size in viewports) {
      testWidgets('hero at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: size.width - 32,
                  child: const HomeEpic030Hero(),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets('feature grid at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: size.width - 32,
                  child: const HomeEpic030FeatureGrid(),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }
  });
}
