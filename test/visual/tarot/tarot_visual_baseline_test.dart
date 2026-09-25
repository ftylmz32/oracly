/// Phase 7A — structural Tarot visual baselines (test-only harness).
///
/// Asserts settled result states render without overflow/provider.
/// Optional PNG capture via TAROT_VISUAL_CAPTURE=1.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_premium_body.dart';

import 'tarot_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await tarotVisualBindLocale('en');
  });

  group('Narrative result baselines @ canonical 390x844', () {
    testWidgets('K single Narrative result settled', (tester) async {
      final storage = await tarotVisualOpenStorage();
      final key = GlobalKey();
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualCanonicalViewport,
        storage: storage,
        captureKey: key,
        child: tarotVisualResultTree(
          tarotVisualNarrativeContent(
            spreadLabel: 'Single Card',
            cardCount: 1,
            question: 'What deserves my calm attention today?',
          ),
          spread: TarotSpreadType.single,
        ),
      );
      expect(find.byType(ReadingPremiumBody), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tarotVisualMaybeCapture(tester, key, 'K_result_single');
    });

    testWidgets('L threeCard Narrative result settled', (tester) async {
      final storage = await tarotVisualOpenStorage();
      final key = GlobalKey();
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualCanonicalViewport,
        storage: storage,
        captureKey: key,
        child: tarotVisualResultTree(
          tarotVisualNarrativeContent(
            spreadLabel: 'Three Card',
            cardCount: 3,
            question: 'Where am I between past and next step?',
          ),
          spread: TarotSpreadType.threeCard,
        ),
      );
      expect(find.byType(ReadingPremiumBody), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tarotVisualMaybeCapture(tester, key, 'L_result_three');
    });

    testWidgets('M fiveCard Narrative result settled', (tester) async {
      final storage = await tarotVisualOpenStorage();
      final key = GlobalKey();
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualCanonicalViewport,
        storage: storage,
        captureKey: key,
        child: tarotVisualResultTree(
          tarotVisualNarrativeContent(
            spreadLabel: 'Five Card',
            cardCount: 5,
            question: 'What pattern is asking for honesty?',
          ),
          spread: TarotSpreadType.fiveCard,
        ),
      );
      expect(find.byType(ReadingPremiumBody), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tarotVisualMaybeCapture(tester, key, 'M_result_five');
    });

    testWidgets('N long Narrative result settled', (tester) async {
      final storage = await tarotVisualOpenStorage();
      final long = List.filled(12, 'A calm paragraph of reflective prose. ')
          .join();
      final key = GlobalKey();
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualCanonicalViewport,
        storage: storage,
        captureKey: key,
        child: tarotVisualResultTree(
          tarotVisualNarrativeContent(
            spreadLabel: 'Three Card',
            cardCount: 3,
            question: 'How do I carry this threshold with care?',
            narrative: long,
          ),
          spread: TarotSpreadType.threeCard,
        ),
      );
      expect(find.byType(ReadingPremiumBody), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tarotVisualMaybeCapture(tester, key, 'N_result_long');
    });

    testWidgets('O safety result settled', (tester) async {
      final storage = await tarotVisualOpenStorage();
      final key = GlobalKey();
      final content = tarotVisualSafetyContent();
      expect(content.isSafetyResponse, isTrue);
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualCanonicalViewport,
        storage: storage,
        captureKey: key,
        child: tarotVisualResultTree(content),
      );
      expect(find.byType(ReadingPremiumBody), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tarotVisualMaybeCapture(tester, key, 'O_result_safety');
    });

    testWidgets('P recovery result settled', (tester) async {
      final storage = await tarotVisualOpenStorage();
      final key = GlobalKey();
      final content = tarotVisualRecoveryContent();
      expect(content.deliveryKind, TarotReadingDeliveryKind.recovery);
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualCanonicalViewport,
        storage: storage,
        captureKey: key,
        child: tarotVisualResultTree(content),
      );
      expect(find.byType(ReadingPremiumBody), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tarotVisualMaybeCapture(tester, key, 'P_result_recovery');
    });
  });

  group('viewport + text-scale structural', () {
    for (final size in tarotVisualViewports) {
      testWidgets(
        'result no overflow @ ${size.width.toInt()}x${size.height.toInt()}',
        (tester) async {
          final storage = await tarotVisualOpenStorage();
          await tarotVisualPumpSettled(
            tester,
            viewport: size,
            storage: storage,
            child: tarotVisualResultTree(
              tarotVisualNarrativeContent(
                spreadLabel: 'Three Card',
                cardCount: 3,
                question: 'What is the next honest step?',
              ),
            ),
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('text scale 1.3 @ 360x800', (tester) async {
      final storage = await tarotVisualOpenStorage();
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualTextScaleViewport,
        textScale: tarotVisualTextScale,
        storage: storage,
        child: tarotVisualResultTree(
          tarotVisualNarrativeContent(
            spreadLabel: 'Single Card',
            cardCount: 1,
            question: 'What deserves quiet attention?',
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
