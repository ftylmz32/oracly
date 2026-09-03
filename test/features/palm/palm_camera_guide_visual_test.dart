/// Palm camera guide — no hand silhouette, fits small viewports.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/shared/camera/guides/palm_frame_painter.dart';
import 'package:oracly_new/shared/camera/guides/palm_hand_capture_guide.dart';

void main() {
  test('palm guide source has no anatomical hand silhouette painter', () {
    final guide =
        File('lib/shared/camera/guides/palm_hand_capture_guide.dart')
            .readAsStringSync();
    final painter =
        File('lib/shared/camera/guides/palm_frame_painter.dart').readAsStringSync();
    expect(guide, contains('PalmFramePainter'));
    expect(guide, isNot(contains('_HandOutlinePainter')));
    expect(painter, isNot(contains('Thumb')));
    expect(painter, isNot(contains('Fingers')));
    expect(painter, contains('RRect'));
  });

  testWidgets('palm guide paints frame and copy without overflow', (tester) async {
    for (final size in const [
      Size(320, 568),
      Size(360, 640),
      Size(390, 844),
      Size(430, 932),
    ]) {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: size.width,
              height: size.height,
              child: const PalmHandCaptureGuide(
                tip: 'Avucunu cerceveye yerlestir',
                detail: 'Isik yeterince aydinlik olsun',
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.textContaining('Avucunu'), findsOneWidget);
      final paints = tester.widgetList<CustomPaint>(find.byType(CustomPaint));
      expect(
        paints.any((p) => p.painter is PalmFramePainter),
        isTrue,
        reason: 'viewport ' + size.width.toString() + 'x' + size.height.toString(),
      );
    }
  });
}
