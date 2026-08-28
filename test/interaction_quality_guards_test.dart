import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/shared/camera/oracly_capture_preview_actions.dart';
import 'package:oracly_new/shared/widgets/oracly_adaptive_scroll_view.dart';
import 'package:oracly_new/shared/widgets/oracly_gold_button.dart';

void main() {
  testWidgets('adaptive scroll stays scrollable before first measure',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OraclyAdaptiveScrollView(
            child: SizedBox(
              height: 2000,
              child: Text('long'),
            ),
          ),
        ),
      ),
    );
    final scrollable = tester.widget<SingleChildScrollView>(
      find.byType(SingleChildScrollView),
    );
    expect(scrollable.physics, isNot(isA<NeverScrollableScrollPhysics>()));
  });

  testWidgets('capture use button disables when onUse is null', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OraclyCapturePreviewActions(
            useLabel: 'Use',
            retakeLabel: 'Retake',
            onUse: null,
            onRetake: _noop,
          ),
        ),
      ),
    );
    final button = tester.widget<OraclyGoldButton>(find.byType(OraclyGoldButton));
    expect(button.onPressed, isNull);
  });
}

void _noop() {}
