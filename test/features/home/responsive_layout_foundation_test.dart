/// Responsive AppLayout / Home viewport foundation.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/design_system/app_layout.dart';
import 'package:oracly_new/features/home/reference/home_reference_tokens.dart';

void main() {
  testWidgets('phones use full width; tablets soft-cap content', (tester) async {
    Future<double> measure(Size size) async {
      late double measured;
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(size: size),
          child: Builder(
            builder: (context) {
              measured = AppLayout.contentMaxWidth(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return measured;
    }

    expect(await measure(const Size(360, 800)), 360);
    expect(await measure(const Size(412, 915)), 412);
    expect(await measure(const Size(480, 960)), 480);
    expect(await measure(const Size(800, 1280)), 560);
    addTearDown(() => tester.binding.setSurfaceSize(null));
  });

  test('3×2 home grid tiles grow on mid-tall phones', () {
    final at774 = HomeReferenceTokens.layoutFor(774);
    final at900 = HomeReferenceTokens.layoutFor(900);
    expect(at774.moduleTileHeight, greaterThan(70));
    expect(at900.moduleTileHeight, greaterThan(at774.moduleTileHeight));
    expect(at900.moduleTileHeight, lessThanOrEqualTo(240));
    expect(at900.heroSlotHeight, greaterThan(at774.heroArtSize));
    // Three rows + discoveries band inside the grid slot (layout token).
    const discoveriesBand = 34.0;
    const rowCount = 3;
    expect(
      at900.gridSlotHeight,
      closeTo(
        at900.moduleTileHeight * rowCount +
            at900.moduleGap * (rowCount - 1) +
            discoveriesBand,
        0.5,
      ),
    );
  });

  test('hero+grid slots absorb viewport without requiring >=840 tall tier', () {
    final compact = HomeReferenceTokens.layoutFor(680);
    final mid = HomeReferenceTokens.layoutFor(774);
    expect(mid.moduleTileHeight, greaterThan(compact.moduleTileHeight));
    expect(mid.heroSlotHeight, greaterThan(compact.heroSlotHeight));
    // Preferred sizes stay readable; short screens scroll instead of crushing.
    expect(mid.orGuideHeight, greaterThanOrEqualTo(118));
    expect(mid.heroSlotHeight, greaterThanOrEqualTo(160));
    expect(mid.gridSlotHeight, greaterThanOrEqualTo(200));
    expect(mid.moduleTileHeight, greaterThanOrEqualTo(96));
  });
}
