/// Phase 7G — structural viewport + geometry containment (complements pixels).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/screens/reading_history_detail_body.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_footer_actions.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_glass_panel.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_premium_body.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_result_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_result_spread_tile.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/tarot_flow_progress.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_deck_stage.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_phase.dart';
import 'package:oracly_new/features/tarot/ritual/widgets/ritual_card_shell.dart';
import 'package:oracly_new/features/tarot/ritual/widgets/ritual_spread_slot_tile.dart';
import 'package:oracly_new/features/tarot/ritual/widgets/ritual_spread_slots.dart';

import 'tarot_golden_harness.dart';
import 'tarot_golden_history_fixtures.dart';
import 'tarot_visual_harness.dart';

Rect _globalRect(Element el) {
  final box = el.renderObject! as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('en'));

  group('viewport matrix — table / result / history', () {
    for (final size in tarotVisualViewports) {
      final label = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('table intention @ $label', (tester) async {
        await tarotGoldenPumpIntention(tester, viewport: size);
        expect(tester.takeException(), isNull);
      });

      testWidgets('result three @ $label', (tester) async {
        final storage = await tarotVisualOpenStorage();
        await tarotVisualPumpSettled(
          tester,
          viewport: size,
          storage: storage,
          precacheFaces: tarotVisualFaceAssets(3),
          child: tarotVisualResultTree(
            tarotVisualNarrativeContent(
              spreadLabel: 'Three Card',
              cardCount: 3,
              question: 'What is the next honest step?',
            ),
            spread: TarotSpreadType.threeCard,
          ),
        );
        expect(find.byType(ReadingPremiumBody), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('history detail @ $label', (tester) async {
        final storage = await tarotVisualOpenStorage();
        final detail = tarotGoldenHistoryNarrativeDetail();
        await tarotVisualPumpSettled(
          tester,
          viewport: size,
          storage: storage,
          precacheFaces: tarotVisualFaceAssets(3),
          child: ReadingHistoryDetailBody(
            entry: detail.entry,
            model: detail.model,
            content: detail.content,
            personalNote: detail.model.personalNote,
            onEditReflection: () {},
            onDelete: () {},
          ),
        );
        expect(find.byType(ReadingPremiumBody), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('360x800 @ 1.3 text scale', (tester) async {
      final storage = await tarotVisualOpenStorage();
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualTextScaleViewport,
        textScale: tarotVisualTextScale,
        storage: storage,
        precacheFaces: tarotVisualFaceAssets(5),
        child: tarotVisualResultTree(
          tarotVisualNarrativeContent(
            spreadLabel: 'Five Card',
            cardCount: 5,
            question: 'What pattern is asking for honesty?',
          ),
          spread: TarotSpreadType.fiveCard,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(ReadingPremiumBody), findsOneWidget);
      expect(find.byType(ReadingResultSpreadTile), findsNWidgets(5));
    });
  });

  group('result rect containment', () {
    for (final spread in [TarotSpreadType.threeCard, TarotSpreadType.fiveCard]) {
      testWidgets('${spread.name} tiles within field @ 390', (tester) async {
        final storage = await tarotVisualOpenStorage();
        await tarotVisualPumpSettled(
          tester,
          viewport: tarotVisualCanonicalViewport,
          storage: storage,
          precacheFaces: tarotVisualFaceAssets(spread.cardCount),
          child: tarotVisualResultTree(
            tarotVisualNarrativeContent(
              spreadLabel: spread.label,
              cardCount: spread.cardCount,
              question: 'Containment check.',
            ),
            spread: spread,
          ),
        );
        expect(find.byType(ReadingResultSpread), findsOneWidget);
        final fieldEl = find.byType(ReadingResultSpread).evaluate().single;
        final field = _globalRect(fieldEl).inflate(2);
        final tiles = find.byType(ReadingResultSpreadTile).evaluate().toList();
        expect(tiles.length, spread.cardCount);
        for (final tile in tiles) {
          final r = _globalRect(tile);
          expect(field.contains(r.topLeft), isTrue, reason: '$r in $field');
          expect(field.contains(r.bottomRight), isTrue, reason: '$r in $field');
        }
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('CTA reachable after scroll @ 390', (tester) async {
      final storage = await tarotVisualOpenStorage();
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualCanonicalViewport,
        storage: storage,
        precacheFaces: tarotVisualFaceAssets(3),
        child: tarotVisualResultTree(
          tarotVisualNarrativeContent(
            spreadLabel: 'Three Card',
            cardCount: 3,
            question: 'CTA check.',
            narrative: List.filled(20, 'Long reflective prose. ').join(),
          ),
          spread: TarotSpreadType.threeCard,
        ),
      );
      expect(find.byType(ReadingFooterActions), findsOneWidget);
      await tester.ensureVisible(find.byType(ReadingFooterActions));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('ritual rect containment', () {
    testWidgets('three partial slots contained @ 390', (tester) async {
      final storage = await tarotVisualOpenStorage();
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualCanonicalViewport,
        storage: storage,
        wrapSafeArea: false,
        precacheFaces: tarotVisualFaceAssets(2),
        child: tarotGoldenRitualSurface(
          spread: TarotSpreadType.threeCard,
          placed: [tarotVisualReveal(0), tarotVisualReveal(1)],
          phase: TarotTablePhase.draw,
        ),
      );
      expect(find.byType(RitualSpreadSlots), findsOneWidget);
      expect(find.byType(RitualCardFace), findsNWidgets(2));
      expect(find.byType(TarotTableDeckStage), findsOneWidget);
      final fieldEl = find.byType(RitualSpreadSlots).evaluate().single;
      final field = _globalRect(fieldEl).inflate(4);
      for (final tile in find.byType(RitualSpreadSlotTile).evaluate()) {
        final r = _globalRect(tile);
        expect(field.contains(r.center), isTrue, reason: '$r center in $field');
      }
      expect(tester.takeException(), isNull);
    });
  });

  group('history structural honesty', () {
    testWidgets('crossroads identity + narrative reopen', (tester) async {
      final entries = tarotGoldenMixedHistoryEntries();
      final cross = entries.firstWhere((e) => e.spreadType == 'crossroads');
      final five = entries.firstWhere((e) => e.spreadType == 'fiveCard');
      expect(cross.displayTitle, isNot(equals(five.displayTitle)));
      expect(cross.moodIcon, isNot(equals(five.moodIcon)));

      final storage = await tarotVisualOpenStorage();
      final detail = tarotGoldenHistoryNarrativeDetail();
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualCanonicalViewport,
        storage: storage,
        precacheFaces: tarotVisualFaceAssets(3),
        child: ReadingHistoryDetailBody(
          entry: detail.entry,
          model: detail.model,
          content: detail.content,
          personalNote: detail.model.personalNote,
          onEditReflection: () {},
          onDelete: () {},
        ),
      );
      expect(detail.model.resultMode, 'narrativeV2');
      expect(find.byType(ReadingPremiumBody), findsOneWidget);
      expect(find.byType(ReadingGlassPanel), findsNothing);
      expect(find.byType(TarotFlowProgress), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  group('locale structural smoke', () {
    for (final locale in ['tr', 'ru']) {
      testWidgets('result three localized $locale', (tester) async {
        OraclyL10n.bind(locale);
        final storage = await tarotVisualOpenStorage();
        await tarotVisualPumpSettled(
          tester,
          viewport: tarotVisualCanonicalViewport,
          storage: storage,
          precacheFaces: tarotVisualFaceAssets(3),
          child: tarotVisualResultTree(
            tarotVisualNarrativeContent(
              spreadLabel: TarotSpreadType.threeCard.label,
              cardCount: 3,
              question: 'Locale fit check.',
            ),
            spread: TarotSpreadType.threeCard,
          ),
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
