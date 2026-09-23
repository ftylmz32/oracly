/// Phase 5C — localization completeness, alias parity, copy safety, geometry.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/app_string_tables.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_geometry_descriptor.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_catalog.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_copy_safety.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_enums.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_localization_contract.dart';

void main() {
  final catalog = SignatureSpreadCatalog.launch;

  group('Phase 5C localization completeness', () {
    test('all catalog keys exist and resolve TR/EN/RU', () {
      final result =
          SignatureSpreadLocalizationContract.validateCatalog(catalog);
      expect(result.issues, isEmpty, reason: '${result.issues}');
      for (final d in catalog) {
        expect(
          SignatureSpreadLocalizationContract.validateDefinition(d).isValid,
          isTrue,
        );
      }
    });

    test('no resolved raw-key fallback', () {
      final result =
          SignatureSpreadLocalizationContract.validateCatalog(catalog);
      expect(
        result.issues.where(
          (i) => i.violation == SignatureLocalizationViolation.rawKeyFallback,
        ),
        isEmpty,
      );
    });
  });

  group('legacy blurb alias parity', () {
    test('threeCard.blurb == three.blurb TR/EN/RU', () {
      for (final lang in ['tr', 'en', 'ru']) {
        expect(
          AppStringTables.lookup(lang, 'tarot.spread.threeCard.blurb'),
          AppStringTables.lookup(lang, 'tarot.spread.three.blurb'),
        );
      }
    });

    test('fiveCard.blurb == five.blurb TR/EN/RU', () {
      for (final lang in ['tr', 'en', 'ru']) {
        expect(
          AppStringTables.lookup(lang, 'tarot.spread.fiveCard.blurb'),
          AppStringTables.lookup(lang, 'tarot.spread.five.blurb'),
        );
      }
    });
  });

  group('Crossroads product copy', () {
    test('exact title / blurb / purpose', () {
      expect(AppStringTables.lookup('tr', 'tarot.spread.crossroads'), 'Yol Ayrımı');
      expect(AppStringTables.lookup('en', 'tarot.spread.crossroads'), 'Crossroads');
      expect(AppStringTables.lookup('ru', 'tarot.spread.crossroads'), 'Перекрёсток');
      expect(
        AppStringTables.lookup('tr', 'tarot.spread.crossroads.blurb'),
        'İki yol · Gerilim · Rehberlik · Yön',
      );
      expect(
        AppStringTables.lookup('en', 'tarot.spread.crossroads.blurb'),
        'Two paths · Tension · Counsel · Direction',
      );
      expect(
        AppStringTables.lookup('ru', 'tarot.spread.crossroads.blurb'),
        'Два пути · Напряжение · Подсказка · Направление',
      );
      expect(
        AppStringTables.lookup('en', 'tarot.spread.crossroads.purpose'),
        'See both options, the tension between them, and the next step that feels most honest to you.',
      );
    });

    test('exact position labels (4)', () {
      expect(AppStringTables.lookup('en', 'tarot.pos.option_a'), 'Option A');
      expect(AppStringTables.lookup('en', 'tarot.pos.option_b'), 'Option B');
      expect(AppStringTables.lookup('en', 'tarot.pos.tension'), 'Tension');
      expect(AppStringTables.lookup('en', 'tarot.pos.counsel'), 'Counsel');
    });

    test('exact guiding questions (5)', () {
      expect(
        AppStringTables.lookup('en', 'tarot.spread.crossroads.guide.option_a'),
        'What dynamic does option A reveal?',
      );
      expect(
        AppStringTables.lookup('en', 'tarot.spread.crossroads.guide.option_b'),
        'What dynamic does option B reveal?',
      );
      expect(
        AppStringTables.lookup('en', 'tarot.spread.crossroads.guide.tension'),
        'What is the real tension between these two options?',
      );
      expect(
        AppStringTables.lookup('en', 'tarot.spread.crossroads.guide.counsel'),
        'What support or perspective should I consider while deciding?',
      );
      expect(
        AppStringTables.lookup('en', 'tarot.spread.crossroads.guide.direction'),
        'What could my next honest step be?',
      );
    });
  });

  group('copy certainty safety', () {
    test('Phase 5 purpose/guide/blurb free of certainty language', () {
      expect(SignatureSpreadCopySafety.scanCatalog(catalog), isEmpty);
    });
  });

  group('geometry descriptors', () {
    test('coverage = 4, slot counts, branching', () {
      expect(SignatureGeometryDescriptors.all, hasLength(4));
      expect(SignatureGeometryDescriptors.single.slotCount, 1);
      expect(SignatureGeometryDescriptors.threeLinear.slotCount, 3);
      expect(SignatureGeometryDescriptors.fiveLinear.slotCount, 5);
      expect(SignatureGeometryDescriptors.fiveDecision.slotCount, 5);
      expect(SignatureGeometryDescriptors.fiveDecision.decisionBranching, isTrue);
      for (final d in [
        SignatureGeometryDescriptors.single,
        SignatureGeometryDescriptors.threeLinear,
        SignatureGeometryDescriptors.fiveLinear,
      ]) {
        expect(d.decisionBranching, isFalse);
      }
    });

    test('catalog cardCount ↔ geometry slotCount parity', () {
      for (final d in catalog) {
        final geo = SignatureGeometryDescriptors.byHook(d.signatureGeometryHook);
        expect(geo.slotCount, d.cardCount, reason: d.spreadId);
        if (d.signatureGeometryHook == SignatureGeometryHook.fiveDecision) {
          expect(geo.decisionBranching, isTrue);
        } else {
          expect(geo.decisionBranching, isFalse);
        }
      }
    });
  });

  group('existing live copy firewall', () {
    test('live titles unchanged', () {
      expect(AppStringTables.lookup('tr', 'tarot.spread.single'), 'Tek Kart');
      expect(AppStringTables.lookup('en', 'tarot.spread.single'), 'One Card');
      expect(AppStringTables.lookup('ru', 'tarot.spread.single'), 'Одна карта');
      expect(AppStringTables.lookup('tr', 'tarot.spread.threeCard'), 'Üç Kart');
      expect(AppStringTables.lookup('en', 'tarot.spread.threeCard'), 'Three Cards');
      expect(AppStringTables.lookup('ru', 'tarot.spread.threeCard'), 'Три карты');
      expect(AppStringTables.lookup('tr', 'tarot.spread.fiveCard'), 'Derin Açılım');
      expect(AppStringTables.lookup('en', 'tarot.spread.fiveCard'), 'Deep Spread');
      expect(
        AppStringTables.lookup('ru', 'tarot.spread.fiveCard'),
        'Глубокий расклад',
      );
    });

    test('legacy blurbs and single.blurb unchanged', () {
      expect(
        AppStringTables.lookup('tr', 'tarot.spread.single.blurb'),
        'Bugün bilmem gereken ne?',
      );
      expect(
        AppStringTables.lookup('en', 'tarot.spread.single.blurb'),
        'What do I need to know today?',
      );
      expect(
        AppStringTables.lookup('ru', 'tarot.spread.single.blurb'),
        'Что мне нужно знать сегодня?',
      );
      expect(
        AppStringTables.lookup('tr', 'tarot.spread.three.blurb'),
        'Geçmiş · Şimdi · Gelecek',
      );
      expect(
        AppStringTables.lookup('en', 'tarot.spread.three.blurb'),
        'Past · Present · Future',
      );
      expect(
        AppStringTables.lookup('ru', 'tarot.spread.three.blurb'),
        'Прошлое · Настоящее · Будущее',
      );
      expect(
        AppStringTables.lookup('tr', 'tarot.spread.five.blurb'),
        'Durum · Zorluk · Güç · Yön',
      );
      expect(
        AppStringTables.lookup('en', 'tarot.spread.five.blurb'),
        'Situation · Challenge · Strength · Direction',
      );
      expect(
        AppStringTables.lookup('ru', 'tarot.spread.five.blurb'),
        'Ситуация · Трудность · Сила · Путь',
      );
    });
  });
}
