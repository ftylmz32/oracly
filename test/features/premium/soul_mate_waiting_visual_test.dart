/// SoulMate wait — dark portrait cinema, never a spinner.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/design_system/loading_cinema/loading_stage_soulmate.dart';
import 'package:oracly_new/core/design_system/loading_cinema/oracly_loading_cinema.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_waiting.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';

void main() {
  testWidgets('waiting uses portrait cinema, not a spinner', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: SoulMateDrawWaiting())),
      ),
    );
    await tester.pump();

    expect(find.text(SoulMateCopy.drawing), findsOneWidget);
    expect(find.byType(OraclyLoadingCinema), findsOneWidget);
    expect(find.byType(LoadingStageSoulMate), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('before the slow threshold the initial drawing copy remains', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SoulMateDrawWaiting(slowAfter: Duration(seconds: 28)),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(SoulMateCopy.drawingSlowTitle), findsNothing);
    expect(find.text(SoulMateCopy.drawing), findsOneWidget);
  });

  testWidgets('recreated waiting view keeps slow state from operation time', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SoulMateDrawWaiting(
            activeSince: DateTime.now().subtract(const Duration(seconds: 29)),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text(SoulMateCopy.drawingSlowTitle), findsOneWidget);
    expect(find.text(SoulMateCopy.retry), findsNothing);
  });

  testWidgets(
    'after the slow threshold active processing stays calm and has no retry or failure copy',
    (tester) async {
      var retryCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SoulMateDrawWaiting(
              slowAfter: const Duration(milliseconds: 20),
              onRetry: () => retryCalls++,
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 21));

      expect(find.text(SoulMateCopy.drawingSlowTitle), findsOneWidget);
      expect(find.textContaining(SoulMateCopy.drawingSlowBody), findsOneWidget);
      expect(
        find.textContaining(SoulMateCopy.drawingSlowSecondary),
        findsOneWidget,
      );
      expect(find.text(SoulMateCopy.retry), findsNothing);
      expect(find.text(ResilienceCopy.slowResponse), findsNothing);
      expect(find.text(SoulMateCopy.failureTemporary), findsNothing);
      expect(retryCalls, 0);
    },
  );
}
