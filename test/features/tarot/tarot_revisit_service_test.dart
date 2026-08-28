/// Smart revisit resolves from real tarot history only.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/features/tarot/revisit/tarot_revisit_service.dart';

ReadingModel _reading({
  required String id,
  String? intention,
  String? readingType,
  String summary = 'Özet.',
  DateTime? at,
}) =>
    ReadingModel(
      id: id,
      cardId: 0,
      cardName: 'The Star',
      cardImageAsset: 'a',
      spreadType: 'Üç Kart',
      aiSummary: summary,
      createdAt: at ?? DateTime(2026, 8, 10),
      intention: intention,
      readingType: readingType,
    );

void main() {
  test('returns null without prior completed readings', () {
    expect(TarotRevisitService.fromHistory(const []), isNull);
  });

  test('surfaces career revisit from topic metadata', () {
    final context = TarotRevisitService.fromHistory([
      _reading(
        id: 'r1',
        readingType: 'career',
        intention: 'Kariyerimde neye odaklanmalıyım?',
      ),
    ]);
    expect(context, isNotNull);
    expect(context!.topicLabel, isNotNull);
    expect(context.spreadLabel, contains('3'));
  });

  test('fromHistory ignores same-day readings', () {
    final now = DateTime(2026, 8, 19);
    expect(
      TarotRevisitService.fromHistory(
        [
          _reading(
            id: 'today',
            readingType: 'career',
            summary: 'Bugünkü açılım.',
            at: now,
          ),
        ],
        now: now,
      ),
      isNull,
    );
  });

  test('fromHistory prefers older relevant reading', () {
    final now = DateTime(2026, 8, 19);
    final context = TarotRevisitService.fromHistory(
      [
        _reading(
          id: 'today',
          readingType: 'career',
          at: now,
        ),
        _reading(
          id: 'old',
          readingType: 'career',
          intention: 'Kariyerimde neye odaklanmalıyım?',
          at: DateTime(2026, 8, 10),
        ),
      ],
      now: now,
    );
    expect(context?.reading.id, 'old');
  });

  test('forConversation matches older career reading to iş topic', () {
    final now = DateTime(2026, 8, 19);
    final context = TarotRevisitService.forConversation(
      conversationTopic: 'iş',
      readings: [
        _reading(
          id: 'today',
          readingType: 'career',
          summary: 'Bugünkü açılım.',
          at: now,
        ),
        _reading(
          id: 'old',
          readingType: 'career',
          intention: 'Kariyerimde neye odaklanmalıyım?',
          summary: 'Kariyer tarafında yavaş bir geçiş görünüyor.',
          at: DateTime(2026, 8, 10),
        ),
      ],
      now: now,
    );
    expect(context, isNotNull);
    expect(context!.reading.id, 'old');
  });

  test('forConversation ignores vague topics', () {
    expect(
      TarotRevisitService.forConversation(
        conversationTopic: 'kararsızlık',
        readings: [
          _reading(id: 'r1', readingType: 'career'),
        ],
      ),
      isNull,
    );
  });

  test('prior excerpt stays observational and clipped', () {
    final reading = _reading(
      id: 'r2',
      intention: 'İş değiştirmeli miyim?',
      summary: 'Kariyer tarafında yavaş bir geçiş görünüyor. '
          'Acele etmeden adım adım ilerlemek daha uygun olabilir.',
    );
    final excerpt = TarotRevisitService.priorExcerpt(reading);
    expect(excerpt.toLowerCase(), contains('kariyer'));
    expect(excerpt.length, lessThanOrEqualTo(141));
  });
}
