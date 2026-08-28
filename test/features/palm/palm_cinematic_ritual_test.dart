/// Palm cinematic ritual — real hand, soft light, no fake scan HUD.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/palm/presentation/palm_analysis_canvas.dart';
import 'package:oracly_new/features/palm/presentation/palm_hand_wait.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('tr'));

  testWidgets('hand wait shows analysis canvas, not a spinner', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: PalmHandWait(
            message: 'Bakıyorum',
            subtitle: 'Sakin',
            path: 'does-not-exist.jpg',
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(PalmAnalysisCanvas), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  test('analyzing hint refuses medical scan language', () {
    final hint = PalmCopy.analyzingHint.toLowerCase();
    expect(hint.contains('tıbbi') || hint.contains('medical'), isTrue);
    expect(hint.contains('mm') || hint.contains('pixel'), isFalse);
    final disclaimer = PalmCopy.disclaimer.toLowerCase();
    expect(
      disclaimer.contains('sembolik') || disclaimer.contains('symbolic'),
      isTrue,
    );
    expect(
      disclaimer.contains('teşhis') || disclaimer.contains('diagnosis'),
      isTrue,
    );
  });
}
