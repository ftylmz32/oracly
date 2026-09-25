/// Phase 7E — Narrative result hierarchy, geometry, honesty, performance.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_narrative_hero.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_narrative_selector.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_premium_body.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_result_mode.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_result_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_story_relations.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_story_strip.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/ritual/geometry/tarot_spread_geometry_resolver.dart';
import 'package:oracly_new/features/tarot/ritual/geometry/tarot_spread_visual_kind.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('en'));

  group('7E result mode', () {
    test('V2 uses live gate — not card count', () {
      expect(
        ReadingResultModeResolver.of(TarotSpreadType.threeCard),
        ReadingResultMode.narrativeV2,
      );
      expect(
        ReadingResultModeResolver.of(TarotSpreadType.fiveCard),
        ReadingResultMode.narrativeV2,
      );
      // Crossroads is also 5 cards but never V2 via gate.
      expect(
        ReadingResultModeResolver.of(TarotSpreadType.crossroads),
        ReadingResultMode.legacy,
      );
      expect(
        ReadingResultModeResolver.of(TarotSpreadType.sevenCard),
        ReadingResultMode.legacy,
      );
    });

    test('fiveCard and Crossroads stay distinct geometry kinds', () {
      expect(
        TarotSpreadGeometryResolver.kindFor(TarotSpreadType.fiveCard),
        TarotSpreadVisualKind.fiveLinear,
      );
      expect(
        TarotSpreadGeometryResolver.kindFor(TarotSpreadType.crossroads),
        TarotSpreadVisualKind.fiveDecision,
      );
    });
  });

  group('7E narrative selector', () {
    test('distinct summary + synthesis shows opening once', () {
      final s = ReadingNarrativeSelector.select(
        _content(
          general: 'A short opening lead about patience.',
          synthesis: 'The longer primary synthesis holds the main story body '
              'with several calm reflective sentences about the threshold.',
        ),
      );
      expect(s.openingSummary, contains('opening lead'));
      expect(s.primaryNarrative, contains('primary synthesis'));
      expect(s.openingSummary, isNot(equals(s.primaryNarrative)));
    });

    test('summary == synthesis omits duplicate opening', () {
      const same = 'One coherent story told once.';
      final s = ReadingNarrativeSelector.select(
        _content(general: same, synthesis: same),
      );
      expect(s.openingSummary, isEmpty);
      expect(s.primaryNarrative, same);
    });

    test('empty synthesis falls back to generalMeaning', () {
      final s = ReadingNarrativeSelector.select(
        _content(general: 'Fallback body.', synthesis: ''),
      );
      expect(s.primaryNarrative, 'Fallback body.');
    });

    test('direction prefers closingMessage', () {
      final s = ReadingNarrativeSelector.select(
        _content(
          general: 'g',
          synthesis: 's',
          closing: 'Calm direction.',
          advice: 'Advice fallback.',
        ),
      );
      expect(s.direction, 'Calm direction.');
    });
  });

  group('7E relation honesty', () {
    testWidgets('Narrative V2 omits local ReadingStoryRelations prose',
        (tester) async {
      final content = _content(
        general: 'Summary.',
        synthesis: 'Primary narrative for three cards.',
        cards: 3,
      );
      // Local helper still produces prose — must not appear in V2 UI.
      expect(ReadingStoryRelations.of(content), isNotEmpty);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReadingPremiumBody(
                content: content,
                spread: TarotSpreadType.threeCard,
                sectionMaster: 1,
                panelOpacity: 1,
                ambientPhase: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text(TarotPolishCopy.relationsTitle), findsNothing);
      expect(find.byType(ReadingNarrativeHero), findsOneWidget);
      expect(find.textContaining('Primary narrative'), findsWidgets);
    });
  });

  group('7E memory honesty', () {
    test('no typed memory UI data → no fabricated recurrence copy in selector',
        () {
      final s = ReadingNarrativeSelector.select(
        _content(general: 'g', synthesis: 's'),
      );
      expect(s.primaryNarrative.toLowerCase(), isNot(contains('saw this before')));
      expect(s.primaryNarrative.toLowerCase(), isNot(contains('recurring')));
    });
  });

  group('7E result geometry', () {
    for (final size in const [
      Size(320, 568),
      Size(390, 844),
      Size(412, 915),
    ]) {
      testWidgets(
        'fiveCard geometry no horizontal strip @ ${size.width.toInt()}',
        (tester) async {
          await tester.binding.setSurfaceSize(size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final content = _content(
            general: 'g',
            synthesis: 'Five card primary narrative.',
            cards: 5,
            label: 'Five Card',
          );
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(size: size),
                child: Scaffold(
                  body: SingleChildScrollView(
                    child: ReadingPremiumBody(
                      content: content,
                      spread: TarotSpreadType.fiveCard,
                      sectionMaster: 1,
                      panelOpacity: 1,
                      ambientPhase: 0,
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(find.byType(ReadingResultSpread), findsOneWidget);
          expect(find.byType(ReadingStoryStrip), findsNothing);
          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('Crossroads internal uses fiveDecision path', (tester) async {
      final content = _content(
        general: 'g',
        synthesis: 'Crossroads internal.',
        cards: 5,
        label: 'Crossroads',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingResultSpread(
              content: content,
              spread: TarotSpreadType.crossroads,
              progress: 1,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(ReadingResultSpread), findsOneWidget);
      expect(find.byType(ReadingStoryStrip), findsNothing);
    });
  });

  group('7E performance firewall', () {
    test('ReadingScreen has no live ReadingFloatingParticles', () {
      final src = File(
        'lib/features/tarot/presentation/screens/reading_screen.dart',
      ).readAsStringSync();
      expect(src.contains('ReadingFloatingParticles('), isFalse);
    });

    test('footer has no perpetual pulse AnimationController', () {
      final src = File(
        'lib/features/tarot/presentation/widgets/ai_reading/reading_footer_actions.dart',
      ).readAsStringSync();
      expect(src.contains('AnimationController'), isFalse);
      expect(src.contains('_pulse'), isFalse);
    });

    test('V2 sections never call ReadingStoryRelations as authority', () {
      final src = File(
        'lib/features/tarot/presentation/widgets/ai_reading/reading_premium_sections.dart',
      ).readAsStringSync();
      expect(src, contains('isNarrativeV2'));
      expect(src, contains("v2 ? '' : ReadingStoryRelations.of(content)"));
      expect(src.toLowerCase(), isNot(contains('lucky energy')));
    });
  });

  group('7E hierarchy UI', () {
    testWidgets('question + full primary narrative visible', (tester) async {
      const synthesis = 'Full primary Narrative body that must remain visible '
          'without being treated as lucky energy.';
      final content = _content(
        general: 'Short overview lead.',
        synthesis: synthesis,
        cards: 3,
        question: 'What deserves honesty today?',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ReadingPremiumBody(
                content: content,
                spread: TarotSpreadType.threeCard,
                sectionMaster: 1,
                panelOpacity: 1,
                ambientPhase: 0,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('What deserves honesty today?'), findsOneWidget);
      expect(find.textContaining('Full primary Narrative'), findsWidgets);
      expect(find.textContaining('Lucky Energy'), findsNothing);
      expect(find.text(TarotPolishCopy.storyTitle), findsOneWidget);
    });
  });
}

AiReadingContent _content({
  required String general,
  required String synthesis,
  String closing = 'One calm direction.',
  String advice = '',
  int cards = 1,
  String label = 'Three Card',
  String? question,
}) {
  final drawn = [
    for (var i = 0; i < cards; i++)
      TarotDrawnCard(
        card: CardRevealSpread.forIndex(i).card,
        positionIndex: i,
        isReversed: i.isOdd,
        positionLabel: 'P$i',
      ),
  ];
  return AiReadingContent(
    cardName: label,
    tagline: 'Reflection',
    generalMeaning: general,
    love: '',
    career: '',
    money: '',
    spiritualGuidance: '',
    luckyEnergy: synthesis,
    dailyAdvice: advice,
    imageAsset: 'star.png',
    rarityColor: const Color(0xFF9B6DFF),
    drawnCards: drawn,
    spreadLabel: label,
    closingMessage: closing,
    userQuestion: question,
  );
}
