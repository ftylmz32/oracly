/// Phase 7G — committed pixel golden masters (matchesGoldenFile).
///
/// Update intentionally:
///   flutter test --update-goldens test/visual/tarot/tarot_golden_master_test.dart
/// Then run WITHOUT --update-goldens (twice) to confirm.
///
/// Masters live in test/goldens/tarot/. Normal runs never auto-update.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/screens/reading_history_detail_body.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_glass_panel.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_premium_body.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/reading_history/reading_history_data.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/reading_history/reading_history_list_card.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/tarot_flow_progress.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_background.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_phase.dart';
import 'package:oracly_new/features/tarot/ritual/table/tarot_table_spread_overlay.dart';
import 'package:oracly_new/features/tarot/ritual/widgets/ritual_card_shell.dart';
import 'package:oracly_new/features/tarot/ritual/widgets/ritual_spread_slots.dart';

import 'tarot_golden_harness.dart';
import 'tarot_golden_history_fixtures.dart';
import 'tarot_visual_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await tarotVisualBindLocale('en');
  });

  group('Family A — live table', () {
    testWidgets('A1 table_intention', (tester) async {
      final key = await tarotGoldenPumpIntention(tester);
      expect(find.byType(TarotTableBackground), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tarotGoldenExpect(tester, key, 'table_intention');
    });

    testWidgets('A2 table_spread_picker', (tester) async {
      final storage = await tarotVisualOpenStorage();
      final key = GlobalKey();
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualCanonicalViewport,
        storage: storage,
        captureKey: key,
        wrapSafeArea: false,
        child: tarotGoldenSpreadPickerSurface(),
      );
      expect(find.byType(TarotTableSpreadOverlay), findsOneWidget);
      expect(find.textContaining('Seven'), findsNothing);
      expect(find.textContaining('Celtic'), findsNothing);
      expect(find.textContaining('Crossroads'), findsNothing);
      expect(find.textContaining('Yol Ayrımı'), findsNothing);
      expect(TarotTableSpreadOverlay.options, [
        TarotSpreadType.single,
        TarotSpreadType.threeCard,
        TarotSpreadType.fiveCard,
      ]);
      expect(tester.takeException(), isNull);
      await tarotGoldenExpect(tester, key, 'table_spread_picker');
    });

    testWidgets('A3 table_draw_ready_three', (tester) async {
      final storage = await tarotVisualOpenStorage();
      final key = GlobalKey();
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualCanonicalViewport,
        storage: storage,
        captureKey: key,
        wrapSafeArea: false,
        precacheFaces: const [],
        child: tarotGoldenRitualSurface(
          spread: TarotSpreadType.threeCard,
          placed: const [],
          phase: TarotTablePhase.draw,
          showFlight: true,
        ),
      );
      expect(find.byType(TarotTableBackground), findsOneWidget);
      expect(find.byType(RitualCardFace), findsNothing);
      expect(tester.takeException(), isNull);
      await tarotGoldenExpect(tester, key, 'table_draw_ready_three');
    });

    testWidgets('A4 table_draw_ready_five', (tester) async {
      final storage = await tarotVisualOpenStorage();
      final key = GlobalKey();
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualCanonicalViewport,
        storage: storage,
        captureKey: key,
        wrapSafeArea: false,
        child: tarotGoldenRitualSurface(
          spread: TarotSpreadType.fiveCard,
          placed: const [],
          phase: TarotTablePhase.draw,
          showFlight: true,
        ),
      );
      expect(tester.takeException(), isNull);
      await tarotGoldenExpect(tester, key, 'table_draw_ready_five');
    });
  });

  group('Family B — ritual settled partials', () {
    testWidgets('B1 ritual_three_one_settled', (tester) async {
      final storage = await tarotVisualOpenStorage();
      final key = GlobalKey();
      final placed = [tarotVisualReveal(0)];
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualCanonicalViewport,
        storage: storage,
        captureKey: key,
        wrapSafeArea: false,
        precacheFaces: tarotVisualFaceAssets(1),
        child: tarotGoldenRitualSurface(
          spread: TarotSpreadType.threeCard,
          placed: placed,
          phase: TarotTablePhase.draw,
          showFlight: true,
        ),
      );
      expect(find.byType(RitualSpreadSlots), findsOneWidget);
      expect(find.byType(RitualCardFace), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tarotGoldenExpect(
        tester,
        key,
        'ritual_three_one_settled',
        precacheFaces: tarotVisualFaceAssets(1),
      );
    });

    testWidgets('B2 ritual_three_two_settled', (tester) async {
      final storage = await tarotVisualOpenStorage();
      final key = GlobalKey();
      final faces = tarotVisualFaceAssets(2);
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualCanonicalViewport,
        storage: storage,
        captureKey: key,
        wrapSafeArea: false,
        precacheFaces: faces,
        child: tarotGoldenRitualSurface(
          spread: TarotSpreadType.threeCard,
          placed: [tarotVisualReveal(0), tarotVisualReveal(1, reversed: true)],
          phase: TarotTablePhase.draw,
          showFlight: true,
        ),
      );
      expect(find.byType(RitualCardFace), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await tarotGoldenExpect(
        tester,
        key,
        'ritual_three_two_settled',
        precacheFaces: faces,
      );
    });

    testWidgets('B3 ritual_five_partial', (tester) async {
      final storage = await tarotVisualOpenStorage();
      final key = GlobalKey();
      final faces = tarotVisualFaceAssets(3);
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualCanonicalViewport,
        storage: storage,
        captureKey: key,
        wrapSafeArea: false,
        precacheFaces: faces,
        child: tarotGoldenRitualSurface(
          spread: TarotSpreadType.fiveCard,
          placed: [
            tarotVisualReveal(0),
            tarotVisualReveal(1, reversed: true),
            tarotVisualReveal(2),
          ],
          phase: TarotTablePhase.draw,
          showFlight: true,
        ),
      );
      expect(find.byType(RitualCardFace), findsNWidgets(3));
      expect(tester.takeException(), isNull);
      await tarotGoldenExpect(
        tester,
        key,
        'ritual_five_partial',
        precacheFaces: faces,
      );
    });
  });

  group('Family C — Narrative result', () {
    Future<void> resultGolden(
      WidgetTester tester, {
      required String name,
      required Widget child,
      Iterable<String> faces = const [],
    }) async {
      final storage = await tarotVisualOpenStorage();
      final key = GlobalKey();
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualCanonicalViewport,
        storage: storage,
        captureKey: key,
        precacheFaces: faces,
        child: child,
      );
      expect(find.byType(ReadingPremiumBody), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tarotGoldenExpect(tester, key, name, precacheFaces: faces);
    }

    testWidgets('C1 result_single_narrative', (tester) async {
      await resultGolden(
        tester,
        name: 'result_single_narrative',
        faces: tarotVisualFaceAssets(1),
        child: tarotVisualResultTree(
          tarotVisualNarrativeContent(
            spreadLabel: 'Single Card',
            cardCount: 1,
            question: 'What deserves my calm attention today?',
          ),
          spread: TarotSpreadType.single,
        ),
      );
    });

    testWidgets('C2 result_three_narrative', (tester) async {
      await resultGolden(
        tester,
        name: 'result_three_narrative',
        faces: tarotVisualFaceAssets(3),
        child: tarotVisualResultTree(
          tarotVisualNarrativeContent(
            spreadLabel: 'Three Card',
            cardCount: 3,
            question: 'Where am I between past and next step?',
          ),
          spread: TarotSpreadType.threeCard,
        ),
      );
    });

    testWidgets('C3 result_five_narrative', (tester) async {
      await resultGolden(
        tester,
        name: 'result_five_narrative',
        faces: tarotVisualFaceAssets(5),
        child: tarotVisualResultTree(
          tarotVisualNarrativeContent(
            spreadLabel: 'Five Card',
            cardCount: 5,
            question: 'What pattern is asking for honesty?',
          ),
          spread: TarotSpreadType.fiveCard,
        ),
      );
    });

    testWidgets('C4 result_long_narrative', (tester) async {
      final long = List.filled(12, 'A calm paragraph of reflective prose. ')
          .join();
      await resultGolden(
        tester,
        name: 'result_long_narrative',
        faces: tarotVisualFaceAssets(3),
        child: tarotVisualResultTree(
          tarotVisualNarrativeContent(
            spreadLabel: 'Three Card',
            cardCount: 3,
            question: 'How do I carry this threshold with care?',
            summary: 'A brief lead into a longer reading.',
            narrative: long,
          ),
          spread: TarotSpreadType.threeCard,
        ),
      );
    });

    testWidgets('C5 result_safety', (tester) async {
      await resultGolden(
        tester,
        name: 'result_safety',
        child: tarotVisualResultTree(tarotVisualSafetyContent()),
      );
    });

    testWidgets('C6 result_recovery', (tester) async {
      await resultGolden(
        tester,
        name: 'result_recovery',
        faces: tarotVisualFaceAssets(1),
        child: tarotVisualResultTree(tarotVisualRecoveryContent()),
      );
    });
  });

  group('Family D — history', () {
    testWidgets('D1 history_list_mixed', (tester) async {
      final storage = await tarotVisualOpenStorage();
      final key = GlobalKey();
      final entries = tarotGoldenMixedHistoryEntries();
      final faces = tarotVisualFaceAssets(6);
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualCanonicalViewport,
        storage: storage,
        captureKey: key,
        precacheFaces: faces,
        child: ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, i) => ReadingHistoryListCard(
            entry: entries[i],
            entrance: 1,
            onTap: () {},
          ),
        ),
      );
      final cross = entries.firstWhere((e) => e.spreadType == 'crossroads');
      final five = entries.firstWhere((e) => e.spreadType == 'fiveCard');
      expect(cross.displayTitle, isNot(equals(five.displayTitle)));
      expect(cross.moodIcon, isNot(equals(five.moodIcon)));
      expect(entries.any((e) => e.filter == HistorySpreadFilter.seven), isTrue);
      expect(tester.takeException(), isNull);
      await tarotGoldenExpect(
        tester,
        key,
        'history_list_mixed',
        precacheFaces: faces,
      );
    });

    testWidgets('D2 history_detail_narrative', (tester) async {
      final storage = await tarotVisualOpenStorage();
      final key = GlobalKey();
      final detail = tarotGoldenHistoryNarrativeDetail();
      final faces = tarotVisualFaceAssets(3);
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualCanonicalViewport,
        storage: storage,
        captureKey: key,
        precacheFaces: faces,
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
      expect(find.byType(ReadingGlassPanel), findsNothing);
      expect(find.byType(TarotFlowProgress), findsNothing);
      expect(tester.takeException(), isNull);
      await tarotGoldenExpect(
        tester,
        key,
        'history_detail_narrative',
        precacheFaces: faces,
      );
    });

    testWidgets('D3 history_detail_crossroads', (tester) async {
      final storage = await tarotVisualOpenStorage();
      final key = GlobalKey();
      final detail = tarotGoldenHistoryCrossroadsDetail();
      final faces = tarotVisualFaceAssets(5);
      await tarotVisualPumpSettled(
        tester,
        viewport: tarotVisualCanonicalViewport,
        storage: storage,
        captureKey: key,
        precacheFaces: faces,
        child: ReadingHistoryDetailBody(
          entry: detail.entry,
          model: detail.model,
          content: detail.content,
          personalNote: null,
          onEditReflection: () {},
          onDelete: () {},
        ),
      );
      expect(detail.model.spreadType, 'crossroads');
      expect(find.byType(ReadingPremiumBody), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tarotGoldenExpect(
        tester,
        key,
        'history_detail_crossroads',
        precacheFaces: faces,
      );
    });
  });
}
