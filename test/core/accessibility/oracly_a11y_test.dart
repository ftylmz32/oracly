/// OraclyA11y floors — touch, contrast, text scale.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/accessibility/oracly_a11y.dart';

void main() {
  test('touch floor is at least 44', () {
    expect(OraclyA11y.minTouchTarget, greaterThanOrEqualTo(44));
  });

  test('gold and cream floors stay readable', () {
    expect(OraclyA11y.goldOnDark, greaterThanOrEqualTo(0.88));
    expect(OraclyA11y.quietGold, greaterThanOrEqualTo(0.84));
    expect(OraclyA11y.quietGoldMuted, greaterThanOrEqualTo(0.76));
    expect(OraclyA11y.secondaryCream, greaterThanOrEqualTo(0.78));
    expect(OraclyA11y.hintCream, greaterThanOrEqualTo(0.68));
    expect(OraclyA11y.iconGoldIdle, greaterThanOrEqualTo(0.75));
  });

  test('body text scale follows system above 1.4; chrome stays capped', () {
    final scaled = OraclyA11y.clampAppTextScaler(const TextScaler.linear(2.0));
    expect(scaled.scale(10), closeTo(20.0, 0.01));
    final chrome =
        OraclyA11y.clampChromeTextScaler(const TextScaler.linear(2.0));
    expect(chrome.scale(10), closeTo(12.0, 0.01));
  });

  testWidgets('ensureMinTouch expands small children', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: OraclyA11y.ensureMinTouch(
              child: const SizedBox(width: 12, height: 12),
            ),
          ),
        ),
      ),
    );
    final box = tester.getSize(find.byType(ConstrainedBox).first);
    expect(box.width, greaterThanOrEqualTo(44));
    expect(box.height, greaterThanOrEqualTo(44));
  });
}
