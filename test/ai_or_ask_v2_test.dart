/// AI Sohbet vs OR'a Sor V2 — modes, context, follow-up, isolation.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/conversation_copy.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/personality/or_living_voice.dart';
import 'package:oracly_new/core/security/ai_error_sanitizer.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import 'package:oracly_new/features/ai/oracle_conversation/services/oracle_conversation_responder.dart';
import 'package:oracly_new/features/ai/oracle_conversation/services/oracle_followup_copy.dart';
import 'package:oracly_new/features/ai/oracle_conversation/services/oracle_tarot_followup_copy.dart';
import 'package:oracly_new/features/ai/services/followup_question_resolve.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';

OracleReadingContext _tarot() {
  return const OracleReadingContext(
    sessionId: 'tarot_1',
    kind: OracleReadingKind.tarot,
    sourceLabel: 'Tarot',
    spreadLabel: 'Üç Kart',
    deckId: 'rider-waite',
    deckName: 'Rider-Waite',
    readingTitle: 'Üç Kart Açılımı',
    cardsSummary:
        'Geçmiş · id:0 · The Fool · Düz\nŞimdi · id:1 · The Moon · Ters',
    interpretationSummary:
        'Bağ ve net konuşma öne çıkıyor. Tek net cümle söyle.',
    cardNames: ['The Fool', 'The Moon'],
    cardIds: [0, 1],
  );
}

OracleReadingContext _dream() {
  return OracleReadingContextSources.dream(
    id: 'dream_1',
    narrative: 'Rüyamda uzun bir yılan evin içinden geçti.',
    analysis: 'Yılan, dönüşüm ve sınır temasını büyütüyor.',
    symbols: const ['yılan', 'ev'],
    emotionalTheme: 'Huzursuz bir uyanış.',
  );
}

void main() {
  test('loading and error copy match the spec', () {
    expect(
      ConversationCopy.thinkingLabel,
      isIn(OrLivingVoice.thinkingPool(OrLivingSurface.or)),
    );
    expect(
      ConversationCopy.oracleThinkingLabel,
      isIn(OrLivingVoice.thinkingPool(OrLivingSurface.or)),
    );
    expect(ConversationCopy.oracleUnavailable, contains('ulaşamadım'));
    expect(ConversationCopy.oracleUnavailable, contains('Bir daha deneyelim'));
    expect(ResilienceCopy.oracleSendFailed, contains('Bağlantı koptu'));
    expect(ResilienceCopy.oracleSendFailed, contains('Bir daha deneyelim'));
    expect(CompanionCopy.connectionError, contains('ulaşamadım'));
    expect(CompanionCopy.connectionError, contains('deneyelim'));
    expect(CompanionCopy.retry, 'Tekrar dene');
    expect(ResilienceCopy.retryAction, 'TEKRAR DENE');
  });

  test('OR suggestions depend on reading kind and sendable', () {
    expect(
      OracleConversationSuggestions.chipsFor(OracleReadingKind.tarot),
      ConversationCopy.oracleSuggestions,
    );
    expect(
      OracleConversationSuggestions.chipsFor(OracleReadingKind.dream),
      ConversationCopy.dreamOracleSuggestions,
    );
    expect(
      OracleConversationSuggestions.chipsFor(OracleReadingKind.astrology),
      ConversationCopy.astrologyOracleSuggestions,
    );
    expect(
      OracleConversationSuggestions.chipsFor(OracleReadingKind.birthChart),
      ConversationCopy.birthChartOracleSuggestions,
    );
    expect(
      OracleConversationSuggestions.chipsFor(OracleReadingKind.coffee),
      ConversationCopy.coffeeOracleSuggestions,
    );
    expect(ConversationCopy.oracleSuggestions.first, contains('en önemli'));
    expect(ConversationCopy.dreamOracleSuggestions.first, contains('sembol'));
  });

  test('AI Sohbet answers topics without injecting a reading', () {
    const responder = CompanionResponder();
    final tarot = responder.respond(
      request: const InsightRequest(text: 'Tarot nedir?'),
      context: const ReflectionContext(),
    );
    final coffee = responder.respond(
      request: const InsightRequest(text: 'Kahve falı ne anlatır?'),
      context: const ReflectionContext(),
    );
    expect(tarot.body.toLowerCase(), contains('tarot'));
    expect(tarot.body, isNot(contains('The Fool')));
    expect(tarot.body, isNot(contains('Geçmiş: The Moon')));
    expect(coffee.body.toLowerCase(), contains('kahve'));
    expect(coffee.body.trim().endsWith('?'), isFalse);
  });

  test('OR follow-ups keep reading context', () {
    final first = OracleTarotFollowupCopy.respond(
      context: _tarot(),
      question: 'Bu kart ne anlatıyor?',
    );
    final second = OracleTarotFollowupCopy.respond(
      context: _tarot(),
      question: 'İlişki açısından?',
      priorUser: const ['Bu kart ne anlatıyor?'],
    );
    final third = OracleTarotFollowupCopy.respond(
      context: _tarot(),
      question: 'Peki karşı taraf?',
      priorUser: const ['Bu kart ne anlatıyor?', 'İlişki açısından?'],
    );
    expect(first, isNotEmpty);
    expect(second.toLowerCase(), anyOf(contains('aşk'), contains('duygusal')));
    expect(second, isNot(contains('Düşünmek için')));
    expect(third.toLowerCase(), anyOf(contains('aşk'), contains('duygusal')));
    expect(
      FollowupQuestionResolve.expand(
        current: 'İlişki açısından?',
        priorUser: const ['Bu kart ne anlatıyor?'],
      ),
      contains('Bu kart ne anlatıyor?'),
    );
  });

  test('contexts do not leak across reading kinds', () {
    final dreamAnswer = OracleFollowupCopy.respond(
      context: _dream(),
      question: 'Bu rüyadaki en önemli sembol ne?',
    );
    final tarotAnswer = OracleTarotFollowupCopy.respond(
      context: _tarot(),
      question: 'Bu açılımın en önemli mesajı ne?',
    );
    expect(dreamAnswer.toLowerCase(), contains('yılan'));
    expect(dreamAnswer, isNot(contains('The Fool')));
    expect(dreamAnswer, isNot(contains('Üç Kart')));
    expect(tarotAnswer, contains('Tek net cümle'));
    expect(tarotAnswer.toLowerCase(), isNot(contains('yılan')));
  });

  test('astrology and coffee OR contexts stay structured', () {
    final astrology = OracleReadingContextSources.astrology(
      id: 'a1',
      signLabel: 'Koç',
      daily: 'Bugün tempo tut.',
      love: 'Net bir cümle iyi gelir.',
      career: 'Tek işe odaklan.',
      caution: 'Acele kararları beklet.',
    );
    expect(astrology.fullInterpretation, contains('Burç: Koç'));
    expect(astrology.fullInterpretation, contains('Kaynak:'));
    expect(astrology.fullInterpretation, contains('Bugün tempo tut.'));
    expect(astrology.fullInterpretation, isNot(contains('Okuma türü:')));
    final coffee = OracleReadingContextSources.coffee(
      CoffeeReading(
        id: 'c1',
        createdAt: DateTime(2026, 8, 9),
        overall: 'Fincanda duruluk var.',
        love: 'Yakınlık.',
        career: 'Sabır.',
        money: 'Denge.',
        nearFuture: 'Yavaşla.',
        takeaway: 'Sakin kal.',
      ),
    );
    final coffeeAnswer = OracleFollowupCopy.respond(
      context: coffee,
      question: 'Aşk konusunda ne görünüyor?',
    );
    expect(coffeeAnswer.toLowerCase(), contains('aşk'));
    expect(coffeeAnswer, isNot(contains('kesin tarih')));
  });

  test('API errors never expose secrets', () {
    final message = AiErrorSanitizer.publicMessage(
      error: 'Unauthorized sk-secretKEY123 from OPENAI_API_KEY=abc',
    );
    expect(message, ResilienceCopy.aiUnavailable);
    expect(message.toLowerCase(), isNot(contains('sk-')));
    expect(message.toLowerCase(), isNot(contains('api_key')));
  });

  test('OR responder answers dream and tarot directly', () async {
    const responder = OracleConversationResponder();
    final dream = await responder.respond(
      context: _dream(),
      userMessage: 'Bu rüyanın duygusal teması ne?',
    );
    final tarot = await responder.respond(
      context: _tarot(),
      userMessage: 'Aşk açısından ne söylüyor?',
    );
    expect(dream.toLowerCase(), contains('duygu'));
    expect(dream, isNot(contains('Düşünmek için')));
    expect(tarot.toLowerCase(), anyOf(contains('aşk'), contains('duygusal')));
    expect(tarot, isNot(contains('Düşünmek için')));
  });
}
