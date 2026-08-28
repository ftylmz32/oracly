import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/home/epic032/home_epic032_daily_energy.dart';
import 'package:oracly_new/features/home/epic032/home_epic032_feature_grid.dart';
import 'package:oracly_new/features/home/epic032/home_epic032_header.dart';
import 'package:oracly_new/features/home/epic032/home_epic032_hero.dart';

void main() {
  const viewports = <Size>[
    Size(360, 800),
    Size(393, 852),
    Size(412, 915),
    Size(430, 932),
  ];

  group('EPIC-032 home widgets — no overflow', () {
    for (final size in viewports) {
      testWidgets('header at ${size.width.toInt()}x${size.height.toInt()}',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: size.width - 48,
                child: const HomeEpic032Header(),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

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
                  child: const HomeEpic032Hero(),
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
                  child: const HomeEpic032FeatureGrid(),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
      });

      testWidgets(
          'daily energy at ${size.width.toInt()}x${size.height.toInt()}',
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
                  child: const HomeEpic032DailyEnergy(),
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
