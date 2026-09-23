/// Phase 5F.1 — shadow exception contract + spread display localization.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/tarot/copy/tarot_l10n.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/history/tarot_history_privacy.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_evaluator.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_input.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_result.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_status.dart';

SignatureSpreadShadowCard _c({
  int ritual = 0,
  bool rev = false,
  int index = 0,
}) =>
    SignatureSpreadShadowCard(
      ritualCardId: ritual,
      isReversed: rev,
      positionIndex: index,
    );

SignatureSpreadShadowResult _eval({
  required TarotSpreadType type,
  required List<SignatureSpreadShadowCard> cards,
}) =>
    SignatureSpreadShadowEvaluator.evaluate(
      input: SignatureSpreadShadowInput(
        sessionId: 's1',
        readingId: 'r1',
        languageCode: 'en',
        spreadType: type,
        cards: cards,
        questionRaw: 'What should I notice today?',
      ),
    );

ReadingModel _history({
  required String spreadType,
  required List<ReadingCardSnapshot> cards,
}) =>
    ReadingModel(
      id: 'h1',
      cardId: cards.first.cardId,
      cardName: cards.first.cardName,
      cardImageAsset: cards.first.cardImageAsset,
      spreadType: spreadType,
      aiSummary: 'A quiet reflection.',
      createdAt: DateTime(2026, 9, 22),
      cards: cards,
    );

ReadingCardSnapshot _snap(int id, String name) => ReadingCardSnapshot(
      cardId: id,
      cardName: name,
      cardImageAsset: 'x.png',
      positionIndex: 0,
    );

void main() {
  tearDown(() => OraclyL10n.bind(AppLocale.tr));

  group('shadow exception contract', () {
    test('duplicate physical card → evidenceBuildFailed, no request', () {
      final r = _eval(
        type: TarotSpreadType.threeCard,
        cards: [
          _c(ritual: 0, index: 0),
          _c(ritual: 0, index: 1),
          _c(ritual: 1, index: 2),
        ],
      );
      expect(r.ok, isFalse);
      expect(r.failureCode, SignatureShadowFailureCode.evidenceBuildFailed);
      expect(r.classicalRequest, isNull);
      expect(r.enrichedRequest, isNull);
    });

    test('source catches only NarrativeEvidenceException', () {
      final src = File(
        'lib/features/tarot/signature_spreads/'
        'signature_spread_shadow_classical.dart',
      ).readAsStringSync();
      expect(src.contains('on NarrativeEvidenceException'), isTrue);
      expect(src.contains('catch (_)'), isFalse);
      expect(src.contains('catch (Object'), isFalse);
      expect(src.contains('catch (Exception'), isFalse);
      expect(
        src.contains("import '../narrative/evidence/narrative_evidence_error.dart';"),
        isTrue,
      );
    });
  });

  group('spread display localization', () {
    test('known machine ids TR/EN/RU', () {
      OraclyL10n.bind('tr');
      expect(TarotL10n.spreadFromStorage('single'), 'Tek Kart');
      expect(TarotL10n.spreadFromStorage('threeCard'), 'Üç Kart');
      expect(TarotL10n.spreadFromStorage('fiveCard'), 'Derin Açılım');
      expect(TarotL10n.spreadFromStorage('sevenCard'), 'Yedi Kart');
      expect(TarotL10n.spreadFromStorage('celticCross'), 'Kelt Haçı');
      expect(TarotL10n.spreadFromStorage('crossroads'), 'Yol Ayrımı');

      OraclyL10n.bind('en');
      expect(TarotL10n.spreadFromStorage('single'), 'One Card');
      expect(TarotL10n.spreadFromStorage('threeCard'), 'Three Cards');
      expect(TarotL10n.spreadFromStorage('fiveCard'), 'Deep Spread');
      expect(TarotL10n.spreadFromStorage('sevenCard'), 'Seven Cards');
      expect(TarotL10n.spreadFromStorage('celticCross'), 'Celtic Cross');
      expect(TarotL10n.spreadFromStorage('crossroads'), 'Crossroads');

      OraclyL10n.bind('ru');
      expect(TarotL10n.spreadFromStorage('single'), 'Одна карта');
      expect(TarotL10n.spreadFromStorage('threeCard'), 'Три карты');
      expect(TarotL10n.spreadFromStorage('fiveCard'), 'Глубокий расклад');
      expect(TarotL10n.spreadFromStorage('sevenCard'), 'Семь карт');
      expect(TarotL10n.spreadFromStorage('celticCross'), 'Кельтский крест');
      expect(TarotL10n.spreadFromStorage('crossroads'), 'Перекрёсток');
    });

    test('legacy TR stored title → current EN', () {
      OraclyL10n.bind('en');
      expect(TarotL10n.spreadFromStorage('Tek Kart'), 'One Card');
      expect(TarotL10n.spreadFromStorage('Üç Kart'), 'Three Cards');
      expect(TarotL10n.spreadFromStorage('Üç Kart Açılımı'), 'Three Cards');
      expect(TarotL10n.spreadFromStorage('Beş Kart'), 'Deep Spread');
      expect(TarotL10n.spreadFromStorage('Yedi Kart'), 'Seven Cards');
      expect(TarotL10n.spreadFromStorage('Kelt Haçı'), 'Celtic Cross');
      expect(TarotHistoryPrivacy.spreadTitle('Üç Kart'), 'Three Cards');
    });

    test('legacy EN stored title → current RU', () {
      OraclyL10n.bind('ru');
      expect(TarotL10n.spreadFromStorage('One Card'), 'Одна карта');
      expect(TarotL10n.spreadFromStorage('Three Cards'), 'Три карты');
      expect(TarotL10n.spreadFromStorage('Deep Spread'), 'Глубокий расклад');
      expect(TarotL10n.spreadFromStorage('Seven Cards'), 'Семь карт');
      expect(TarotL10n.spreadFromStorage('Celtic Cross'), 'Кельтский крест');
      expect(TarotHistoryPrivacy.spreadTitle('Three Cards'), 'Три карты');
    });

    test('legacy RU stored title → current TR', () {
      OraclyL10n.bind('tr');
      expect(TarotL10n.spreadFromStorage('Одна карта'), 'Tek Kart');
      expect(TarotL10n.spreadFromStorage('Три карты'), 'Üç Kart');
      expect(TarotL10n.spreadFromStorage('Глубокий расклад'), 'Derin Açılım');
      expect(TarotL10n.spreadFromStorage('Семь карт'), 'Yedi Kart');
      expect(TarotL10n.spreadFromStorage('Кельтский крест'), 'Kelt Haçı');
      expect(TarotHistoryPrivacy.spreadTitle('Три карты'), 'Üç Kart');
    });

    test('Crossroads machine-id all 3 locales', () {
      OraclyL10n.bind('tr');
      expect(TarotL10n.spreadFromStorage('crossroads'), 'Yol Ayrımı');
      OraclyL10n.bind('en');
      expect(TarotL10n.spreadFromStorage('crossroads'), 'Crossroads');
      OraclyL10n.bind('ru');
      expect(TarotL10n.spreadFromStorage('crossroads'), 'Перекрёсток');
    });

    test('blank and unknown fail safe to generic Tarot title', () {
      OraclyL10n.bind('tr');
      expect(TarotL10n.spreadFromStorage(''), 'Tarot Açılımı');
      expect(TarotL10n.spreadFromStorage('   '), 'Tarot Açılımı');
      expect(TarotL10n.spreadFromStorage('garbage_internal_value'), 'Tarot Açılımı');
      expect(TarotHistoryPrivacy.spreadTitle('garbage_internal_value'), 'Tarot Açılımı');

      OraclyL10n.bind('en');
      expect(TarotL10n.spreadFromStorage('garbage_internal_value'), 'Tarot reading');
      expect(TarotHistoryPrivacy.spreadTitle(''), 'Tarot reading');

      OraclyL10n.bind('ru');
      expect(TarotL10n.spreadFromStorage('garbage_internal_value'), 'Расклад Таро');
    });

    test('raw garbage never returned', () {
      const garbage = 'garbage_internal_value';
      for (final lang in ['tr', 'en', 'ru']) {
        OraclyL10n.bind(lang);
        expect(TarotL10n.spreadFromStorage(garbage), isNot(garbage));
        expect(TarotHistoryPrivacy.spreadTitle(garbage), isNot(garbage));
        expect(TarotL10n.spreadFromStorage(garbage), isNot(contains('garbage')));
      }
    });

    test('privacy classical hardcodes removed', () {
      final src = File(
        'lib/features/tarot/history/tarot_history_privacy.dart',
      ).readAsStringSync();
      expect(src.contains('1 Kart Açılımı'), isFalse);
      expect(src.contains('3 Kart Açılımı'), isFalse);
      expect(src.contains('5 Kart Açılımı'), isFalse);
      expect(src.contains('7 Kart Açılımı'), isFalse);
      expect(src.contains("spreadTitle(String spreadType) =>"), isTrue);
      expect(src.contains('TarotL10n.spreadFromStorage'), isTrue);
    });
  });

  group('OracleReadingContext history localization', () {
    test('threeCard TR/EN/RU', () {
      final reading = _history(
        spreadType: 'threeCard',
        cards: [
          _snap(0, 'The Fool'),
          _snap(1, 'The Magician'),
          _snap(2, 'The High Priestess'),
        ],
      );

      OraclyL10n.bind('tr');
      var ctx = OracleReadingContext.fromHistoryReading(reading);
      expect(ctx.spreadLabel, 'Üç Kart');
      expect(ctx.readingTitle, 'Üç Kart');

      OraclyL10n.bind('en');
      ctx = OracleReadingContext.fromHistoryReading(reading);
      expect(ctx.spreadLabel, 'Three Cards');
      expect(ctx.readingTitle, 'Three Cards');

      OraclyL10n.bind('ru');
      ctx = OracleReadingContext.fromHistoryReading(reading);
      expect(ctx.spreadLabel, 'Три карты');
      expect(ctx.readingTitle, 'Три карты');
    });

    test('fiveCard EN/RU', () {
      final reading = _history(
        spreadType: 'fiveCard',
        cards: [
          for (var i = 0; i < 5; i++) _snap(i, 'Card $i'),
        ],
      );

      OraclyL10n.bind('en');
      var ctx = OracleReadingContext.fromHistoryReading(reading);
      expect(ctx.spreadLabel, 'Deep Spread');
      expect(ctx.readingTitle, 'Deep Spread');

      OraclyL10n.bind('ru');
      ctx = OracleReadingContext.fromHistoryReading(reading);
      expect(ctx.spreadLabel, 'Глубокий расклад');
      expect(ctx.readingTitle, 'Глубокий расклад');
    });

    test('Crossroads TR/EN/RU', () {
      final reading = _history(
        spreadType: 'crossroads',
        cards: [
          for (var i = 0; i < 5; i++) _snap(i, 'Card $i'),
        ],
      );

      OraclyL10n.bind('tr');
      var ctx = OracleReadingContext.fromHistoryReading(reading);
      expect(ctx.spreadLabel, 'Yol Ayrımı');
      expect(ctx.readingTitle, 'Yol Ayrımı');

      OraclyL10n.bind('en');
      ctx = OracleReadingContext.fromHistoryReading(reading);
      expect(ctx.spreadLabel, 'Crossroads');
      expect(ctx.readingTitle, 'Crossroads');

      OraclyL10n.bind('ru');
      ctx = OracleReadingContext.fromHistoryReading(reading);
      expect(ctx.spreadLabel, 'Перекрёсток');
      expect(ctx.readingTitle, 'Перекрёсток');
    });

    test('single-card readingTitle remains card name', () {
      OraclyL10n.bind('en');
      final reading = _history(
        spreadType: 'single',
        cards: [_snap(17, 'The Star')],
      );
      final ctx = OracleReadingContext.fromHistoryReading(reading);
      expect(ctx.spreadLabel, 'One Card');
      expect(ctx.readingTitle, 'The Star');
    });
  });
}
