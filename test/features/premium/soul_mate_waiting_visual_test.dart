/// SoulMate wait — dark portrait cinema, never a spinner.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/design_system/loading_cinema/loading_stage_soulmate.dart';
import 'package:oracly_new/core/design_system/loading_cinema/oracly_loading_cinema.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_waiting.dart';

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
}
