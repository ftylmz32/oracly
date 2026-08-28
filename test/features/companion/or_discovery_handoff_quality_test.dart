/// Discovery → OR handoff quality — context without re-explaining.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/companion/services/or_chat_handoff.dart';
import 'package:oracly_new/features/companion/services/or_context_selection_engine.dart';
import 'package:oracly_new/features/companion/services/or_discovery_handoff_quality.dart';
import 'package:oracly_new/features/star_map/services/star_map_reading_service.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('tarot handoff keeps question, cards, interpretation — no ids', () {
    final compact = OrChatHandoff.compact(
      const OracleReadingContext(
        sessionId: 's1',
        spreadLabel: 'Üç Kart',
        deckId: 'classic',
        deckName: 'Classic',
        readingTitle: 'Açılım',
        cardsSummary: 'Geçmiş · id:42 · The Moon · Düz',
        interpretationSummary: 'Küçük ve net bir adım yeterli.',
        userQuestion: 'Ne yapmalıyım?',
        cardNames: ['The Moon'],
        kind: OracleReadingKind.tarot,
        sourceLabel: 'Tarot',
      ),
    );
    expect(compact, contains('Soru: Ne yapmalıyım?'));
    expect(compact, contains('The Moon'));
    expect(compact, contains('Geçmiş'));
    expect(compact, contains('net bir adım'));
    expect(compact, isNot(contains('id:42')));
    expect(compact.length, lessThanOrEqualTo(OrDiscoveryHandoffQuality.maxTotal));
  });

  test('coffee handoff carries labeled observations', () {
    final compact = OrChatHandoff.compact(
      OracleReadingContextSources.coffee(
        CoffeeReading(
          id: 'c1',
          createdAt: DateTime(2026, 8, 9),
          overall: 'Duruluk var.',
          love: 'Yakınlık yumuşak.',
          career: 'Tek bir iş yeter.',
          money: 'Denge.',
          nearFuture: 'Yavaşla.',
          takeaway: 'Sakin kal.',
          symbols: const [],
        ),
      ),
    );
    expect(compact, contains('Kahve'));
    expect(compact, contains('Aşk:'));
    expect(compact, contains('Yön:'));
    expect(compact, isNot(contains('secret')));
  });

  test('astrology and yıldızname keep relevant theme context', () {
    final astro = OrChatHandoff.compact(
      OracleReadingContextSources.astrology(
        id: 'a1',
        signLabel: 'Koç',
        daily: 'Bugün ölçülü ilerle.',
        career: 'İşte sakin adım.',
      ),
    );
    expect(astro, contains('Astroloji'));
    expect(astro, contains('Koç'));
    expect(astro, contains('ölçülü'));
    expect(astro, contains('yerel Güneş burcu kataloğu'));
    expect(astro, isNot(contains('Aşk:')));
    expect(astro, isNot(contains('Kariyer:')));

    final reading = StarMapReadingService.build(now: DateTime(2026, 8, 9));
    final star = OrChatHandoff.compact(
      OracleReadingContextSources.starMap(
        sectionLabel: 'Karmik iz',
        reading: reading,
        sectionLines: const ['Bu bölüm: sabır teması.'],
      ),
    );
    expect(star, contains('Yıldızname'));
    expect(star, contains('Tema: Karmik iz'));
    expect(star, contains('sabır'));
  });

  test('arrival welcome says context is held — no re-explain', () {
    expect(
      OrChatHandoff.arrivalLine(
        const OracleReadingContext(
          sessionId: 't1',
          spreadLabel: 'Tek',
          deckId: 'd',
          deckName: 'D',
          readingTitle: 'T',
          cardsSummary: 'C',
          interpretationSummary: 'Özet',
          kind: OracleReadingKind.tarot,
          sourceLabel: 'Tarot',
        ),
      ),
      contains('kartlar burada'),
    );
    expect(
      OrChatHandoff.arrivalLine(
        const OracleReadingContext(
          sessionId: 'c1',
          spreadLabel: '',
          deckId: '',
          deckName: '',
          readingTitle: 'Kahve',
          cardsSummary: '',
          interpretationSummary: 'Duruluk.',
          kind: OracleReadingKind.coffee,
          sourceLabel: 'Kahve Falı',
        ),
      ),
      contains('Kahve'),
    );
  });

  test('styleHint prefers handoff as INTERPRETATION without dump', () {
    final coffee = OrChatHandoff.compact(
      OracleReadingContextSources.coffee(
        CoffeeReading(
          id: 'c2',
          createdAt: DateTime(2026, 8, 9),
          overall: 'Duruluk.',
          love: 'Yakınlık.',
          career: 'İş.',
          money: 'Denge.',
          nearFuture: 'Yavaş.',
          takeaway: 'Sakin.',
        ),
      ),
    );
    final hint = OrContextSelectionEngine.styleHint(
      currentMessage: 'Bu fal hakkında konuşalım.',
      recentMessages: const [],
      featureHandoff: coffee,
    );
    expect(hint, contains('INTERPRETATION'));
    expect(hint, contains('Kahve'));
    expect(hint.length, lessThanOrEqualTo(480));
  });
}
