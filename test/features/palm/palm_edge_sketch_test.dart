/// Palm edge-sketch smoke — non-null synthetic PNG or null-safe path.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:oracly_new/features/palm/presentation/palm_analysis_canvas.dart';
import 'package:oracly_new/features/palm/presentation/palm_hand_wait.dart';
import 'package:oracly_new/features/palm/presentation/palm_result_sketch_layer.dart';
import 'package:oracly_new/features/palm/services/palm_edge_sketch.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(PalmEdgeSketch.clearCache);

  test('edge sketch returns non-null PNG for synthetic fixture', () {
    final src = img.Image(width: 48, height: 64);
    img.fill(src, color: img.ColorRgba8(40, 28, 48, 255));
    for (var i = 0; i < 48; i++) {
      final y = (i * 64 / 48).round().clamp(0, 63);
      src.setPixelRgba(i, y, 220, 200, 160, 255);
      if (y + 1 < 64) src.setPixelRgba(i, y + 1, 180, 150, 120, 255);
    }
    final png = Uint8List.fromList(img.encodePng(src));
    final out = PalmEdgeSketch.fromBytes(png);
    expect(out, isNotNull);
    expect(out!.length, greaterThan(32));
    expect(out[0], 0x89);
    expect(out[1], 0x50);
  });

  test('edge sketch fail-soft on missing path', () async {
    final out = await PalmEdgeSketch.fromPath(
      'definitely-missing-palm-edge-sketch.png',
    );
    expect(out, isNull);
  });

  testWidgets('analysis canvas pumps without crash', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PalmHandWait(
            message: 'Bakıyorum',
            path: 'does-not-exist-palm.png',
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(PalmAnalysisCanvas), findsOneWidget);
    expect(find.byType(PalmResultSketchLayer), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    // Advance settle + short ritual clock; skip pumpAndSettle (ticker hold).
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 800));
  });
}
