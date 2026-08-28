/// OR mic requesting — quiet gold focus, never a Material spinner.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_voice_slot.dart';
import 'package:oracly_new/features/companion/voice/companion_voice_phase.dart';

void main() {
  testWidgets('requesting mic stays calm and untappable, never a spinner', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CompanionReferenceVoiceSlot(
              phase: CompanionVoicePhase.requesting,
              onTap: () => taps++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);

    // A pending permission request must not fire a second prompt.
    await tester.tap(find.byType(CompanionReferenceVoiceSlot));
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('listening reads as an active mic', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: CompanionReferenceVoiceSlot(
              phase: CompanionVoicePhase.listening,
              onTap: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
  });
}
