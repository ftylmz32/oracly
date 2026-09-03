/// P0 — user-facing AI labels match real execution source.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/transparency_copy.dart';
import 'package:oracly_new/core/domain/models/dream_record.dart';
import 'package:oracly_new/core/domain/repositories/dream_repository.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/oracle_conversation/services/oracle_ai_message_source.dart';
import 'package:oracly_new/features/ai/production/ai_request_exception.dart';
import 'package:oracly_new/features/ai/production/unconfigured_oracly_ai_service.dart';
import 'package:oracly_new/features/astrology/presentation/reference/astrology_reference_kind_note.dart';
import 'package:oracly_new/features/birth_chart/copy/birth_chart_copy.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/unavailable_coffee_analysis.dart';
import 'package:oracly_new/features/companion/services/companion_ai_bridge.dart';
import 'package:oracly_new/features/dream/copy/dream_copy.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';
import 'package:oracly_new/features/star_map/copy/star_map_polish_copy.dart';
import 'package:oracly_new/features/tarot/copy/tarot_polish_copy.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/interpretation/executors/local_interpretation_executor.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_request.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_result.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_detail/card_detail_ai_insight.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/deck_selection/deck_selection_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tarot local catalogue is never labeled AI', () async {
    final local = await LocalInterpretationExecutor().execute(_tarotRequest());
    expect(local.source, InterpretationSource.local);
    expect(TarotPolishCopy.readingTitleLocal, 'Kart yorumu');
    expect(CardDetailAiInsight.title, TarotPolishCopy.readingTitleLocal);
    expect(CardDetailAiInsight.title.toLowerCase(), isNot(contains('ai')));
    expect(
      TarotPolishCopy.readingFootnote(fromAi: false).toLowerCase(),
      isNot(contains('yapay zek')),
    );
    expect(
      TarotPolishCopy.readingFootnote(fromAi: true),
      startsWith(TarotPolishCopy.sourceAi),
    );
  });

  test('dream local fallback is not AI; unconfigured production fails closed',
      () async {
    const localAi = UnconfiguredOraclyAiService(allowsLocalFallback: true);
    final local = await DreamExperienceService(
      repository: _MemDreams(),
      ai: localAi,
    ).analyze(
      narrative: 'Rüyamda uzun bir yılan evden geçti ve sessizce gitti.',
    );
    expect(local.dream.fromAi, isFalse);
    expect(
      DreamCopy.readingFootnote(fromAi: false),
      startsWith(DreamCopy.sourceLocal),
    );
    expect(
      DreamCopy.readingFootnote(fromAi: false).toLowerCase(),
      isNot(contains('yapay zek')),
    );
    expect(
      DreamCopy.readingFootnote(fromAi: true),
      startsWith(DreamCopy.sourceAi),
    );

    const prodAi = UnconfiguredOraclyAiService();
    await expectLater(
      DreamExperienceService(repository: _MemDreams(), ai: prodAi).analyze(
        narrative: 'Rüyamda uzun bir yılan evden geçti ve sessizce gitti.',
      ),
      throwsA(isA<AiRequestException>()),
    );
  });

  test('coffee unavailable never claims vision AI or detected symbols', () async {
    final unavailable = CoffeeCopy.analysisUnavailable.toLowerCase();
    expect(
      unavailable.contains('kullanılamıyor') ||
          unavailable.contains('bakılamıyor') ||
          unavailable.contains('hazırlanamadı'),
      isTrue,
    );
    expect(CoffeeCopy.sourceNote.toLowerCase(), contains('fotoğraf'));
    expect(CoffeeCopy.sourceNote.toLowerCase(), contains('sembolik'));
    expect(CoffeeCopy.sourceNote.toLowerCase(), isNot(contains('kehanet iddiası')));
    expect(CoffeeCopy.disclaimer.toLowerCase(), isNot(contains('yapay zek')));
    expect(
      () => const UnavailableCoffeeAnalysis().analyze(
        const CoffeeImagePick(path: 'cup.jpg', mimeType: 'image/jpeg'),
      ),
      throwsA(isA<CoffeeAnalysisException>()),
    );
  });

  test('astrology catalogue is burç yorumu, not AI or live sky math', () {
    expect(AstrologyReferenceKindNote.label.toLowerCase(), isNot(contains('önizleme')));
    expect(AstrologyReferenceKindNote.detail.toLowerCase(), contains('güneş'));
    expect(AstrologyReferenceKindNote.detail, contains('yansıma'));
    expect(AstrologyReferenceKindNote.detail.toLowerCase(), isNot(contains('hesaplanmaz')));
    expect(AstrologyReferenceKindNote.detail.toLowerCase(), isNot(contains('ai')));
    expect(
      AstrologyReferenceKindNote.detail.toLowerCase(),
      isNot(contains('yapay zek')),
    );
  });

  test('birth chart and yıldızname do not claim full ephemeris or AI', () {
    expect(BirthChartCopy.ephemerisNote, contains('sembolik'));
    expect(BirthChartCopy.ephemerisNote, contains('Güneş burcun'));
    expect(BirthChartCopy.generating, isNot(contains('ephemeris')));
    expect(StarMapPolishCopy.whatItIs.toLowerCase(), contains('sembolik'));
    expect(
      StarMapPolishCopy.whatItIs.toLowerCase(),
      isNot(contains('gökyüzü haritan')),
    );
    expect(StarMapPolishCopy.birthChartHint.toLowerCase(), contains('sembolik'));
    expect(StarMapPolishCopy.skyMessageHint.toLowerCase(), contains('sembolik'));
    expect(StarMapPolishCopy.planetsCatalogueNote.toLowerCase(), contains('sembolik'));
    expect(StarMapPolishCopy.birthChartHint.toLowerCase(), isNot(contains('hesaplanmaz')));
    expect(StarMapPolishCopy.planetsCatalogueNote.toLowerCase(), isNot(contains('hesaplanmaz')));
  });

  test('OR\'a Sor and chat stay fail-closed without fake AI text', () async {
    const ai = UnconfiguredOraclyAiService();
    await expectLater(
      CompanionAiBridge(ai).tryLiveOrFailClosed(userMessage: 'Merhaba'),
      throwsA(isA<AiRequestException>()),
    );
    await expectLater(
      OracleAiMessageSource(ai: ai).reply(
        context: _oracleContext(),
        userMessage: 'Bu kart ne anlatıyor?',
      ),
      throwsA(isA<AiRequestException>()),
    );
    expect(
      TransparencyCopy.interpretationFootnote.toLowerCase(),
      contains('sembolik'),
    );
    expect(
      TransparencyCopy.interpretationFootnote.toLowerCase(),
      isNot(contains('yapay zekâ ile oluşturulur')),
    );
  });

  test('dev local dream/chat fallback cannot masquerade as AI', () async {
    const ai = UnconfiguredOraclyAiService(allowsLocalFallback: true);
    expect(ai.allowsLocalFallback, isTrue);
    expect(ai.isConfigured, isFalse);
    expect(
      await CompanionAiBridge(ai).tryLiveOrFailClosed(userMessage: 'Merhaba'),
      isNull,
    );
    final dream = await DreamExperienceService(
      repository: _MemDreams(),
      ai: ai,
    ).analyze(narrative: 'Rüyamda sessiz bir ev ve açık bir pencere vardı.');
    expect(dream.dream.fromAi, isFalse);
    expect(
      DreamCopy.readingFootnote(fromAi: dream.dream.fromAi).toLowerCase(),
      isNot(contains('yapay zek')),
    );
  });

  test('free tarot deck regression still holds', () {
    expect(TarotDeckCatalogue.decks, hasLength(1));
    expect(TarotDeckCatalogue.decks.first.requiresPremium, isFalse);
    expect(TarotDeckCatalogue.isSelectable('golden'), isFalse);
  });

  test('dream fromAi persists only when set', () {
    final local = Dream(
      id: 'd1',
      narrative: 'Deneme',
      recordedAt: DateTime(2026, 8, 9),
    );
    expect(local.fromAi, isFalse);
    expect(Dream.fromJson(local.toJson()).fromAi, isFalse);
    expect(local.copyWith(fromAi: true).fromAi, isTrue);
  });
}

InterpretationRequest _tarotRequest() {
  return InterpretationRequest(
    requestId: 'r1',
    createdAt: DateTime(2026, 8, 9),
    context: ReadingContext(
      sessionId: 's1',
      spreadType: TarotSpreadType.single,
      spreadLabel: 'Günlük Kart',
      deckId: 'classic',
      language: 'tr',
      readingDate: DateTime(2026, 8, 9),
      cards: const [
        ReadingCardContext(
          cardId: 0,
          cardName: 'Deli',
          positionIndex: 0,
          positionLabel: 'Şimdi',
          positionKey: 'now',
          isReversed: false,
          uprightMeaning: 'Yeni bir başlangıç.',
          reversedMeaning: 'Tereddüt.',
          keywords: ['başlangıç'],
        ),
      ],
    ),
  );
}

OracleReadingContext _oracleContext() {
  return const OracleReadingContext(
    sessionId: 'tarot_1',
    kind: OracleReadingKind.tarot,
    sourceLabel: 'Tarot',
    spreadLabel: 'Tek Kart',
    deckId: 'rider-waite',
    deckName: 'Rider-Waite',
    readingTitle: 'Tek Kart',
    cardsSummary: 'The Star (Düz)',
    interpretationSummary: 'Umut ve sakin duruş.',
    cardNames: ['The Star'],
  );
}

class _MemDreams implements DreamRepository {
  final _items = <DreamRecord>[];

  @override
  Future<List<DreamRecord>> getAll() async => List.of(_items);

  @override
  Future<DreamRecord?> getById(String id) async {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<void> save(DreamRecord record) async {
    _items.removeWhere((e) => e.id == record.id);
    _items.add(record);
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((e) => e.id == id);
  }

  @override
  Future<void> sync() async {}
}
