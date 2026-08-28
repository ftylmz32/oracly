/// Final single-image splash tests.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/constants/app_assets.dart';
import 'package:oracly_new/screens/splash/splash_brand_overlay.dart';
import 'package:oracly_new/screens/splash/splash_completion_gate.dart';
import 'package:oracly_new/screens/splash/splash_destination.dart';
import 'package:oracly_new/screens/splash/splash_final_timeline.dart';

Future<void> _allowSplashArtDecode(WidgetTester tester) async {
  await tester.runAsync(() async {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  });
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  test('Flutter branded animation is ~3 seconds', () {
    expect(SplashBrandOverlay.durationMs, inInclusiveRange(2900, 3200));
    expect(SplashFinalTimeline.durationMs, SplashBrandOverlay.durationMs);
  });

  test('FinalOraclySplash typedef constructs SplashBrandOverlay', () {
    const w = FinalOraclySplash(onDone: _noop);
    expect(w, isA<SplashBrandOverlay>());
  });

  test('final splash asset path is single source', () {
    expect(AppAssets.splashFinal, 'assets/splash/oracly_splash_final.png');
  });

  test('midnight matches native #07050D', () {
    expect(SplashDestination.midnight.toARGB32(), 0xFF07050D);
  });

  test('completion gate blocks finish until art settles', () {
    final g = SplashCompletionGate();
    expect(g.requestFinish(), isFalse);
    expect(g.pendingFinish, isTrue);
    expect(g.onArtSettled(painted: true), isTrue);
    expect(g.artPainted, isTrue);
  });

  test('completion gate allows finish when art already painted', () {
    final g = SplashCompletionGate();
    expect(g.onArtSettled(painted: true), isFalse);
    expect(g.requestFinish(), isTrue);
  });

  test('completion gate unblocks on art failure after animation', () {
    final g = SplashCompletionGate();
    expect(g.requestFinish(), isFalse);
    expect(g.onArtSettled(painted: false), isTrue);
    expect(g.artFailed, isTrue);
  });

  testWidgets('overlay paints final art and completes', (tester) async {
    var done = 0;
    var frames = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashBrandOverlay(
          onDone: () => done++,
          onFirstFrame: () => frames++,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(Image), findsWidgets);
    await _allowSplashArtDecode(tester);
    expect(frames, greaterThanOrEqualTo(1));
    await tester.pump(const Duration(milliseconds: 3100));
    for (var i = 0; i < 30 && done == 0; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(done, 1);
  });

  testWidgets('first frame is never blank — overlay covers midnight',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SplashBrandOverlay(onDone: _noop)),
    );
    await tester.pump();
    expect(find.byType(ColoredBox), findsWidgets);
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('reduced motion still completes with same art', (tester) async {
    var done = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SplashBrandOverlay(
          reduced: true,
          onDone: () => done++,
        ),
      ),
    );
    await tester.pump();
    await _allowSplashArtDecode(tester);
    await tester.pump(const Duration(milliseconds: 1700));
    for (var i = 0; i < 30 && done == 0; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(done, 1);
  });
}

void _noop() {}
