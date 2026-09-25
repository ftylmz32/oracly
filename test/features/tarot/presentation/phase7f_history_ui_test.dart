/// Phase 7F — history filters, titles, Crossroads identity, detail body.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_gate.dart';
import 'package:oracly_new/features/tarot/presentation/screens/reading_history_detail_body.dart';
import 'package:oracly_new/features/tarot/presentation/utils/reading_history_mapper.dart';
import 'package:oracly_new/features/tarot/presentation/utils/saved_reading_parser.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_glass_panel.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_premium_body.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/reading_history/reading_history_data.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/tarot_flow_progress.dart';
import 'package:oracly_new/features/tarot/ritual/geometry/tarot_spread_geometry_resolver.dart';
import 'package:oracly_new/features/tarot/ritual/geometry/tarot_spread_visual_kind.dart';

ReadingModel _model({
  required String id,
  required String spreadType,
  required String cardName,
  String? resultMode,
}) =>
    ReadingModel(
      id: id,
      cardId: 17,
      cardName: cardName,
      cardImageAsset: 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
      spreadType: spreadType,
      aiSummary: '## Summary\nPersisted reflection.',
      createdAt: DateTime.utc(2026, 9, 25, 14, 30),
      resultMode: resultMode,
      cards: [
        ReadingCardSnapshot(
          cardId: 17,
          cardName: 'The Star',
          cardImageAsset: 'lib/assets/images/tarot/major_arcana/17_yildiz.png',
          positionIndex: 0,
          isReversed: false,
        ),
        if (spreadType != 'single')
          ReadingCardSnapshot(
            cardId: 18,
            cardName: 'The Moon',
            cardImageAsset: 'lib/assets/images/tarot/major_arcana/18_ay.png',
            positionIndex: 1,
            isReversed: true,
          ),
      ],
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('en'));

  group('7F history list honest titles + filters', () {
    test('single title is card name', () {
      final entry = ReadingHistoryMapper.fromModel(
        _model(id: 's', spreadType: 'single', cardName: 'The Star'),
      );
      expect(entry.filter, HistorySpreadFilter.single);
      expect(entry.displayTitle, 'The Star');
      expect(entry.moodIcon, Icons.filter_1_rounded);
    });

    test('three title is spread identity — not composite card name', () {
      final entry = ReadingHistoryMapper.fromModel(
        _model(
          id: 't',
          spreadType: 'threeCard',
          cardName: 'The Star',
        ),
      );
      expect(entry.filter, HistorySpreadFilter.three);
      expect(entry.displayTitle, isNot(contains('·')));
      expect(entry.displayTitle.toLowerCase(), contains('three'));
      expect(entry.primaryCardLabel, 'The Star');
    });

    test('five / seven / celtic distinct filters', () {
      expect(
        ReadingHistoryMapper.fromModel(
          _model(id: '5', spreadType: 'fiveCard', cardName: 'The Star'),
        ).filter,
        HistorySpreadFilter.five,
      );
      expect(
        ReadingHistoryMapper.fromModel(
          _model(id: '7', spreadType: 'sevenCard', cardName: 'The Star'),
        ).filter,
        HistorySpreadFilter.seven,
      );
      expect(
        ReadingHistoryMapper.fromModel(
          _model(id: 'c', spreadType: 'celticCross', cardName: 'The Star'),
        ).filter,
        HistorySpreadFilter.celtic,
      );
    });

    test('Crossroads is not aliased to five filter/icon', () {
      final entry = ReadingHistoryMapper.fromModel(
        _model(id: 'x', spreadType: 'crossroads', cardName: 'The Star'),
      );
      expect(entry.filter, HistorySpreadFilter.crossroads);
      expect(entry.filter, isNot(HistorySpreadFilter.five));
      expect(entry.moodIcon, Icons.alt_route_rounded);
      expect(entry.moodIcon, isNot(Icons.filter_5_rounded));
      expect(entry.typeLabel.toLowerCase(), contains('crossroad'));
      expect(
        TarotSpreadGeometryResolver.kindFor(TarotSpreadType.crossroads),
        TarotSpreadVisualKind.fiveDecision,
      );
      expect(TarotSpreadType.crossroads.cardCount, 5);
      // Public picker / Narrative live remain false.
      FeatureFlagRuntime.refreshFromRemote({
        ProductFeatureFlags.tarotNarrativeV2.key: true,
      });
      expect(
        NarrativeTarotLiveGate.shouldUseNarrative(TarotSpreadType.crossroads),
        isFalse,
      );
      FeatureFlagRuntime.refreshFromRemote(const {});
    });
  });

  group('7F history detail uses 7E body', () {
    testWidgets('ReadingPremiumBody present — GlassPanel not canonical',
        (tester) async {
      final model = _model(
        id: 'd1',
        spreadType: 'threeCard',
        cardName: 'The Star',
        resultMode: 'narrativeV2',
      );
      final entry = ReadingHistoryMapper.fromModel(model);
      final content = SavedReadingParser.toContent(entry: entry, model: model);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReadingHistoryDetailBody(
              entry: entry,
              model: model,
              content: content,
              personalNote: null,
              onEditReflection: () {},
              onDelete: () {},
            ),
          ),
        ),
      );
      expect(find.byType(ReadingPremiumBody), findsOneWidget);
      expect(find.byType(ReadingGlassPanel), findsNothing);
      expect(find.byType(TarotFlowProgress), findsNothing);
    });

    testWidgets('viewport 320 / 390 / 412 / 360@1.3 no overflow',
        (tester) async {
      final model = _model(
        id: 'v',
        spreadType: 'threeCard',
        cardName: 'The Star',
        resultMode: 'narrativeV2',
      );
      final entry = ReadingHistoryMapper.fromModel(model);
      final content = SavedReadingParser.toContent(entry: entry, model: model);

      Future<void> pumpAt(Size size, {double textScale = 1}) async {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(
              size: size,
              textScaler: TextScaler.linear(textScale),
            ),
            child: MaterialApp(
              home: Scaffold(
                body: ReadingHistoryDetailBody(
                  entry: entry,
                  model: model,
                  content: content,
                  personalNote: 'A personal note.',
                  onEditReflection: () {},
                  onDelete: () {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      await pumpAt(const Size(320, 568));
      await pumpAt(const Size(390, 844));
      await pumpAt(const Size(412, 915));
      await pumpAt(const Size(360, 800), textScale: 1.3);
      await tester.binding.setSurfaceSize(null);
    });
  });
}
