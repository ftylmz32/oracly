/// BATCH 3A.1 — Palm personalization context reaches the writer only when
/// a trustworthy first name is available, and a reading never blocks or
/// degrades when it is not.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/chat_ai_reply.dart';
import 'package:oracly_new/features/ai/production/models/coffee_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/palm_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/openai/openai_paid_requests.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/discovery_journal/services/discovery_journal_map.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/services/openai_palm_analysis.dart';

const _validAsset = 'lib/assets/images/coffee_ritual_hero.webp';

const _goodOverall =
    'Bu avuç içinde kararların genelde sessizce, uzun bir düşünme süresinin '
    'ardından alındığı görülüyor; hızlı davranmak yerine oturup tartmayı '
    'tercih eden bir yapı bu.';

class _RecordingPalmAi implements OraclyAiService {
  Map<String, dynamic>? lastPersonalization;

  @override
  bool get isConfigured => true;
  @override
  bool get allowsLocalFallback => false;
  @override
  bool get visionAvailable => true;

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
    Map<String, dynamic>? personalization,
  }) async {
    lastPersonalization = personalization;
    return AiOutcome.success(
      const PalmAiAnalysis(
        overall: _goodOverall,
        takeaway: 'Bugün acele etmeden tek bir karara odaklanmak yeterli.',
      ),
    );
  }

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffee({
    required List<int> imageBytes,
    required String mimeType,
    Map<String, dynamic>? personalization,
  }) async => throw UnsupportedError('coffee not used in this test');

  @override
  Future<AiOutcome<ChatAiReply>> chat({
    required String userMessage,
    List<String> priorUser = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) async => throw UnsupportedError('chat not used in this test');

  @override
  Future<AiOutcome<ChatAiReply>> askOracle({
    required ReadingAiContext context,
    required String userMessage,
    List<String> priorUser = const [],
    List<String> observedThemes = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) async => throw UnsupportedError('askOracle not used in this test');

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(
    DreamAiContext context,
  ) async => throw UnsupportedError('dream not used in this test');

  @override
  Future<AiOutcome<ChatAiReply>> generateTarotReading({
    required List<Map<String, dynamic>> cards,
    required String spreadLabel,
    String? userQuestion,
    String? readingTheme,
    Map<String, dynamic>? journeyHints,
  }) async => throw UnsupportedError('tarot not used in this test');
}

void main() {
  test(
    'a trustworthy first name reaches the writer as personalization',
    () async {
      final ai = _RecordingPalmAi();
      final analysis = OpenAiPalmAnalysis(ai: ai, firstName: () => 'Kaya');
      await analysis.analyze(
        const CoffeeImagePick(path: _validAsset),
        hand: PalmHand.right,
      );
      expect(ai.lastPersonalization, {'firstName': 'Kaya'});
    },
  );

  test(
    'no profile name means no personalization — reading still succeeds',
    () async {
      final ai = _RecordingPalmAi();
      final analysis = OpenAiPalmAnalysis(ai: ai, firstName: () => null);
      final reading = await analysis.analyze(
        const CoffeeImagePick(path: _validAsset),
        hand: PalmHand.left,
      );
      expect(ai.lastPersonalization, isNull);
      expect(reading.overall, isNotEmpty);
    },
  );

  test(
    'constructing without a firstName accessor at all never blocks a reading',
    () async {
      final ai = _RecordingPalmAi();
      final analysis = OpenAiPalmAnalysis(ai: ai);
      final reading = await analysis.analyze(
        const CoffeeImagePick(path: _validAsset),
        hand: PalmHand.right,
      );
      expect(ai.lastPersonalization, isNull);
      expect(reading.overall, isNotEmpty);
    },
  );

  test(
    'placeholder-like or email-like names are never sent as personalization',
    () async {
      final ai = _RecordingPalmAi();
      for (final bad in [
        'guest',
        'user',
        'null',
        'someone@example.com',
        '  ',
      ]) {
        final analysis = OpenAiPalmAnalysis(ai: ai, firstName: () => bad);
        await analysis.analyze(
          const CoffeeImagePick(path: _validAsset),
          hand: PalmHand.right,
        );
        expect(ai.lastPersonalization, isNull, reason: 'rejected for "$bad"');
      }
    },
  );

  test(
    'authoritative backend interpretation reaches the composed reading and the Journal unchanged',
    () async {
      final ai = _RecordingPalmAi();
      final analysis = OpenAiPalmAnalysis(ai: ai, firstName: () => 'Kaya');
      final reading = await analysis.analyze(
        const CoffeeImagePick(path: _validAsset),
        hand: PalmHand.right,
      );
      expect(reading.overall, _goodOverall);
      final entry = DiscoveryJournalMap.palm(reading);
      expect(entry.title, contains('kararların genelde sessizce'));
    },
  );

  test(
    'relevant recurring themes reach the writer as personalization',
    () async {
      final ai = _RecordingPalmAi();
      final analysis = OpenAiPalmAnalysis(
        ai: ai,
        relevantThemes: () => ['sınırlar'],
      );
      await analysis.analyze(
        const CoffeeImagePick(path: _validAsset),
        hand: PalmHand.right,
      );
      expect(ai.lastPersonalization, {
        'relevantThemes': ['sınırlar'],
      });
    },
  );

  test(
    'relevant sourced memory reaches writer and lookup failure is soft',
    () async {
      final withMemory = _RecordingPalmAi();
      await OpenAiPalmAnalysis(
        ai: withMemory,
        relevantThemes: () => ['kariyer'],
        memorySummary: (_) => '[tarot | 2026-09-07 | t1] Kariyer kararı.',
      ).analyze(const CoffeeImagePick(path: _validAsset), hand: PalmHand.right);
      expect(withMemory.lastPersonalization!['memorySummary'], contains('t1'));

      final failingMemory = _RecordingPalmAi();
      final reading = await OpenAiPalmAnalysis(
        ai: failingMemory,
        relevantThemes: () => ['kariyer'],
        memorySummary: (_) => throw StateError('memory unavailable'),
      ).analyze(const CoffeeImagePick(path: _validAsset), hand: PalmHand.right);
      expect(reading.overall, isNotEmpty);
      expect(
        failingMemory.lastPersonalization!.containsKey('memorySummary'),
        isFalse,
      );
    },
  );

  test('themes are capped to 3 and blank entries are dropped', () async {
    final ai = _RecordingPalmAi();
    final analysis = OpenAiPalmAnalysis(
      ai: ai,
      relevantThemes: () => ['a', '  ', 'b', 'c', 'd', 'e'],
    );
    await analysis.analyze(
      const CoffeeImagePick(path: _validAsset),
      hand: PalmHand.right,
    );
    expect(ai.lastPersonalization!['relevantThemes'], ['a', 'b', 'c']);
  });

  test('D: personalization is instance-scoped — one accessor never leaks '
      'another instance/profile\'s themes or name', () async {
    final aiA = _RecordingPalmAi();
    final analysisA = OpenAiPalmAnalysis(
      ai: aiA,
      firstName: () => 'Deniz',
      relevantThemes: () => ['karar verme'],
    );
    final aiB = _RecordingPalmAi();
    final analysisB = OpenAiPalmAnalysis(
      ai: aiB,
      firstName: () => 'Kaya',
      relevantThemes: () => ['sınırlar'],
    );
    await analysisA.analyze(
      const CoffeeImagePick(path: _validAsset),
      hand: PalmHand.right,
    );
    await analysisB.analyze(
      const CoffeeImagePick(path: _validAsset),
      hand: PalmHand.left,
    );
    expect(aiA.lastPersonalization, {
      'firstName': 'Deniz',
      'relevantThemes': ['karar verme'],
    });
    expect(aiB.lastPersonalization, {
      'firstName': 'Kaya',
      'relevantThemes': ['sınırlar'],
    });
  });

  test('wire payload includes personalization only when present', () {
    final withName = OpenAiPaidRequests.palm(
      model: 'gpt-test',
      imageBytes: const [1, 2, 3],
      mimeType: 'image/jpeg',
      hand: 'right',
      personalization: const {'firstName': 'Kaya'},
    );
    expect(withName.payload['personalization'], {'firstName': 'Kaya'});

    final withoutName = OpenAiPaidRequests.palm(
      model: 'gpt-test',
      imageBytes: const [1, 2, 3],
      mimeType: 'image/jpeg',
      hand: 'right',
    );
    expect(withoutName.payload.containsKey('personalization'), isFalse);
  });
}
