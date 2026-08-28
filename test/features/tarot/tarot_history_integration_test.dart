/// Completed tarot readings persist into Discovery Journal without extra secrets.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/services/reading_service.dart';
import 'package:oracly_new/features/discovery_journal/copy/discovery_journal_copy.dart';
import 'package:oracly_new/features/discovery_journal/models/discovery_journal_kind.dart';
import 'package:oracly_new/features/discovery_journal/services/discovery_journal_map.dart';
import 'package:oracly_new/features/insights/models/journey_personalization_hints.dart';
import 'package:oracly_new/features/personal_discovery/copy/personal_theme_copy.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/history/tarot_history_privacy.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/reading/reading_story.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../personal_discovery/pde_test_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ReadingService readings;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    readings = ReadingService(
      MockHistoryRepository(storage),
      MockUserRepository(storage),
    );
  });

  test('completed three-card persist is journal-safe', () async {
    final card = CardRevealSpread.forIndex(0).card;
    final saved = await readings.saveFromSession(
      session: ReadingSession(
        id: 's1',
        deckId: 'classic',
        spread: TarotSpreadType.threeCard,
        intention: const TarotIntention(
          text:
              'Bu kararı vermeli miyim yoksa evliliğimi, işimi ve evimi beklemeli miyim?',
          topic: 'general',
        ),
        shuffleSeed: 3,
        startedAt: DateTime(2026, 8, 18),
        drawnCards: [
          TarotDrawnCard(
            card: card,
            positionIndex: 0,
            isReversed: false,
            positionLabel: 'Geçmiş',
          ),
        ],
      ),
      aiSummary: 'Karar vermek bu masada yavaş duruyor. Kısa bir içgörü.',
    );
    expect(saved, isNotNull);
    expect(saved!.createdAt, isNotNull);
    expect(saved.spreadType, 'Üç Kart');
    expect(saved.cards.single.cardId, card.id);
    expect(saved.intention, isNot(contains('evimi beklemeli')));
    expect(saved.intention, contains('Bu kararı vermeli miyim'));
    expect(saved.readingType, 'general');
    expect(saved.journal.summaryExcerpt, isNotEmpty);
    expect(saved.journal.tags, isNotEmpty);

    final row = DiscoveryJournalMap.reading(saved);
    expect(row.kind, DiscoveryJournalKind.tarot);
    expect(row.title, '3 Kart Açılımı');
    expect(row.dateLabel, contains('Ağustos'));
    expect(row.preview, isNotEmpty);
    expect(row.preview, isNot(contains('evimi beklemeli')));
  });

  test('generic and leaking questions are not stored', () async {
    final card = CardRevealSpread.forIndex(1).card;
    final generic = await readings.saveFromSession(
      session: ReadingSession(
        id: 'g1',
        deckId: 'classic',
        spread: TarotSpreadType.single,
        intention: const TarotIntention(text: 'Genel rehberlik'),
        shuffleSeed: 1,
        startedAt: DateTime(2026, 8, 18),
        drawnCards: [
          TarotDrawnCard(card: card, positionIndex: 0, isReversed: false),
        ],
      ),
      aiSummary: 'Sakin bir bakış.',
    );
    expect(generic!.intention, isNull);
    expect(TarotHistoryPrivacy.questionSummary('secret@mail.com'), isNull);
  });

  test('tarot and OR decision evidence can synthesise a real cross theme', () {
    final now = DateTime(2026, 8, 18);
    final profile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: [
          pdeTarot('t1', 'Karar vermek bu dönemde yavaş ilerliyor.', at: now),
        ],
        conversations: [
          pdeOr('o1', 'Karar vermek üzerine durduk.', at: now),
        ],
        coffee: [
          pdeCoffee('c1', 'Değişim yumuşak duruyor.', at: now),
        ],
      ),
      now: now,
    );
    expect(profile.observations.map((o) => o.source), contains('tarot'));
    final decision = profile.crossInsights.where((i) => i.theme == 'karar verme');
    expect(decision, isNotEmpty);
    expect(decision.single.sources, containsAll(['tarot', 'reflection']));
    expect(
      PersonalThemeCopy.crossModal(['karar verme']),
      contains('yeniden karşına çıkıyor'),
    );
    expect(
      DiscoveryJournalCopy.insight(decision.single, now: now),
      contains('Karar verme'),
    );
  });

  test('a later reading does not copy the previous opening wording', () {
    final first = ReadingStory.opening(_ctx(seed: 0));
    final later = ReadingStory.opening(
      _ctx(
        seed: 1,
        hints: JourneyPersonalizationHints(
          priorReadingCount: 1,
          priorOpenings: [JourneyPersonalizationHints.fingerprint(first)],
        ),
      ),
    );
    expect(later, isNot(equals(first)));
    expect(later, isNot(contains('tarafında öne çıkan')));
  });
}

ReadingContext _ctx({
  required int seed,
  JourneyPersonalizationHints? hints,
}) {
  return ReadingContext(
    sessionId: 'anti_$seed',
    spreadType: TarotSpreadType.single,
    spreadLabel: 'Tek Kart',
    deckId: 'classic',
    language: 'tr',
    readingDate: DateTime(2026, 8, 18),
    shuffleSeed: seed,
    journeyHints: hints,
    cards: [
      ReadingCardContext(
        cardId: 17,
        cardName: 'The Star',
        positionIndex: 0,
        positionLabel: 'Şimdi',
        positionKey: 'present',
        isReversed: false,
        uprightMeaning: 'Umut ve yenilenme.',
        reversedMeaning: 'Gecikmiş umut.',
        keywords: const ['umut'],
      ),
    ],
  );
}
