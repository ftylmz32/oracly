/// Phase 4C — Tarot history source adapter (session primary + legacy).
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/services/history_service.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_history_source_adapter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'tarot_4c_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late MockHistoryRepository repo;
  late HistoryService history;
  late TarotReadingRepositoryImpl tarot;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    repo = MockHistoryRepository(storage);
    history = HistoryService(repo);
    tarot = TarotReadingRepositoryImpl.fromStorage(storage);
  });

  Future<List> load({String? owner}) async {
    final r = await TarotHistorySourceAdapter(
      history: history,
      tarotRepository: tarot,
    ).load(currentOwnerId: owner);
    return r.readings;
  }

  test('session primary facts win; ReadingModel enriches intention', () async {
    await tarot.saveSession(
      completedSession(
        id: 'session_1',
        userId: null,
        intention: 'Genel rehberlik',
        topic: null,
        interpretation: 'Session yorumu',
      ),
    );
    await repo.saveReading(
      journalReading(
        id: 'session_1',
        sessionId: 'session_1',
        intention: 'Bu kararı vermeli miyim?',
        readingType: 'career',
        aiSummary: 'Journal yorumu fazla',
      ),
    );

    final rows = await load();
    expect(rows, hasLength(1));
    final row = rows.single;
    expect(row.readingId, 'session_1');
    expect(row.spreadId, 'classical.single');
    expect(row.intentionSummary, contains('kararı'));
    expect(row.topicId, 'career');
    expect(row.interpretationSummary, 'Session yorumu');
    expect(row.cards.single.orientationKnown, isTrue);
    expect(row.cards.single.isReversed, isFalse);
    expect(row.cards.single.positionKey, 'sign');
    expect(row.cards.single.canonicalCardId, 'major_00');
  });

  test('missing positionKey reconstructs from valid index', () async {
    await tarot.saveSession(
      completedSession(id: 's_pos', positionKey: null, positionIndex: 0),
    );
    final rows = await load();
    expect(rows.single.cards.single.positionKey, 'sign');
  });

  test('invalid position index → null positionKey', () async {
    await tarot.saveSession(
      completedSession(id: 's_bad', positionKey: null, positionIndex: 9),
    );
    final rows = await load();
    expect(rows.single.cards.single.positionIndex, isNull);
    expect(rows.single.cards.single.positionKey, isNull);
  });

  test('legacy ReadingModel-only: orientationKnown false', () async {
    await repo.saveReading(
      journalReading(
        id: 'legacy_1',
        intention: 'Bu kararı vermeli miyim?',
        cards: [
          const ReadingCardSnapshot(
            cardId: 0,
            cardName: 'Fool',
            cardImageAsset: 'f',
            positionIndex: 0,
            isReversed: false,
          ),
        ],
      ),
    );
    final rows = await load();
    expect(rows, hasLength(1));
    expect(rows.single.cards.single.orientationKnown, isFalse);
    expect(rows.single.cards.single.positionKey, 'sign');
  });

  test('linked session+journal does not dual-emit', () async {
    await tarot.saveSession(completedSession(id: 'dup'));
    await repo.saveReading(journalReading(id: 'dup', sessionId: 'dup'));
    expect(await load(), hasLength(1));
  });

  test('in-progress session excluded', () async {
    await tarot.saveSession(
      ReadingSession(
        id: 'active',
        deckId: 'rider-waite',
        spread: TarotSpreadType.single,
        intention: const TarotIntention(text: 'x'),
        shuffleSeed: 1,
        startedAt: DateTime.utc(2026, 8, 1),
        status: ReadingSessionStatus.inProgress,
        drawnCards: [
          TarotDrawnCard(card: tarotCard0, positionIndex: 0, isReversed: false),
        ],
      ),
    );
    expect(await load(), isEmpty);
  });

  test('linked owner conflict drops physical reading', () async {
    await tarot.saveSession(completedSession(id: 'c1', userId: 'A'));
    await repo.saveReading(
      journalReading(id: 'c1', sessionId: 'c1', userId: 'B'),
    );
    expect(await load(owner: 'A'), isEmpty);
  });
}
