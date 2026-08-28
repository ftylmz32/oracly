/// UI smoke for AI user flows — no live HTTP (testWidgets fakes HttpClient).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import 'package:oracly_new/features/ai/oracle_conversation/widgets/or_ask_button.dart';
import 'package:oracly_new/features/ai/presentation/widgets/oracle_send_error_banner.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_welcome.dart';

void main() {
  testWidgets('AI Sohbet welcome + error banner + retry copy', (tester) async {
    var retried = false;
    await tester.pumpWidget(
      const MaterialApp(home: CompanionReferenceWelcome()),
    );
    expect(find.text(CompanionCopy.welcomeTitle), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OracleSendErrorBanner(
            message: ResilienceCopy.aiConfigMissing,
            onRetry: () => retried = true,
          ),
        ),
      ),
    );
    expect(find.text(ResilienceCopy.aiConfigMissing), findsOneWidget);
    await tester.tap(find.text(CompanionCopy.retry));
    expect(retried, isTrue);
    expect(find.textContaining('sk-'), findsNothing);
    expect(find.textContaining('OpenAI'), findsNothing);
  });

  testWidgets('OR a Sor CTA is present', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: OrAskButton(
          readingContext: OracleReadingContextSources.dream(
            id: 'd1',
            narrative: 'Ruyamda yagmur yagiyordu sessizce.',
            analysis: 'Yagmur bir arinma hissi tasiyor.',
          ),
        ),
      ),
    );
    expect(find.byType(OrAskButton), findsOneWidget);
  });
}
