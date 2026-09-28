/// G1 — OR text is Premium (or one first-reading deepen). OR text is not
/// billed server-side, so a lapse mid-session must stop the next paid turn.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/companion/controllers/companion_controller.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_actions.dart';
import 'package:oracly_new/features/companion/providers/companion_providers.dart';
import 'package:oracly_new/features/companion/services/first_reading_or_deepen.dart';
import 'package:oracly_new/features/premium/services/premium_dev_override.dart';

import 'g1_or_support.dart';
import 'g1_soulmate_support.dart';

void main() {
  setUp(() {
    OraclyL10n.bind('en');
    PremiumDevOverride.resetDebug();
  });
  tearDown(PremiumDevOverride.resetDebug);

  Future<void> pumpComposer(
    WidgetTester tester,
    G1SoulMateHarness harness,
    CompanionController companion,
  ) async {
    final composer = TextEditingController(text: 'What is asking for my care?');
    addTearDown(composer.dispose);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        ...harness.overrides(),
        companionControllerProvider.overrideWith((ref) => companion),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => sendCompanionComposer(
                ref: ref,
                context: context,
                composer: composer,
                onScrolled: () {},
              ),
              child: const Text('send'),
            ),
          ),
        ),
      ),
    ));
  }

  Future<void> send(WidgetTester tester) async {
    await tester.tap(find.text('send'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
  }

  testWidgets('after Premium lapses mid-session the next text turn is gated',
      (tester) async {
    final harness = await G1SoulMateHarness.open();
    final ai = G1ScriptedAi();
    await pumpComposer(tester, harness, g1Companion(ai: ai, repo: G1ThreadRepo()));
    harness.lapse();

    await send(tester);

    expect(ai.calls, 0);
    expect(harness.status.isPremium, isFalse);
  });

  testWidgets('a stale check that confirms Premium lets the turn through',
      (tester) async {
    final harness = await G1SoulMateHarness.open();
    final ai = G1ScriptedAi();
    await pumpComposer(tester, harness, g1Companion(ai: ai, repo: G1ThreadRepo()));
    harness.stale();

    await send(tester);

    expect(ai.calls, 1);
  });

  testWidgets('a free user still gets the one first-reading deepen',
      (tester) async {
    final harness = await G1SoulMateHarness.open();
    await FirstReadingOrDeepen.markEligible(
        harness.storage, g1FirstTarot.sessionId);
    final ai = G1ScriptedAi();
    final companion =
        g1Companion(ai: ai, repo: G1ThreadRepo(), storage: harness.storage)
          ..applyReadingHandoff(g1FirstTarot);
    await pumpComposer(tester, harness, companion);
    harness.lapse();

    await send(tester);

    expect(ai.calls, 1);
    expect(FirstReadingOrDeepen.isConsumed(harness.storage), isTrue);
  });
}
