/// Real Dream / Coffee user-flow QA against local Fastify.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/domain/models/dream_record.dart';
import 'package:oracly_new/core/domain/repositories/dream_repository.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/coffee/copy/coffee_copy.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/openai_coffee_analysis.dart';
import 'package:oracly_new/features/coffee/services/unavailable_coffee_analysis.dart';
import 'package:oracly_new/features/dream/controllers/dream_analysis_controller.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/services/dream_ai_insight_mapper.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';
import 'package:oracly_new/features/dream/services/dream_understanding_service.dart';

import 'support/ai_e2e_probe.dart';

bool get _live => Platform.environment['ORACLY_E2E'] == '1';

void main() {
  final skip = _live ? false : 'Set ORACLY_E2E=1 with local Fastify running';

  setUpAll(() async {
    if (_live) await detectE2eProvider();
  });

  test('Dream Analysis uses OraclyAiService and typed Turkish error', () async {
    final probe = AiE2eProbe();
    final repo = _MemDreams();
    final controller = DreamAnalysisController(
      DreamExperienceService(repository: repo, ai: e2eLiveAi(probe)),
    );
    await controller.loadHistory();
    expect(controller.history, isEmpty);

    final first = controller.submit(
      narrative: 'Ruyamda uzun bir yilan evden gecti ve sessizce gitti.',
    );
    final second = controller.submit(
      narrative: 'Ruyamda uzun bir yilan evden gecti ve sessizce gitti.',
    );
    await Future.wait([first, second]);
    expect(jsonDecode(probe.lastBody!)['operation'], 'dream_analysis');
    // Controller coalesces concurrent submits — one live request expected.
    expect(probe.requests.length, 1);

    if (e2eProviderConfigured) {
      if (controller.phase == DreamJourneyPhase.error) {
        // Map typed rate-limit into an honest environment failure.
        final msg = controller.errorMessage ?? '';
        if (msg == ResilienceCopy.aiRateLimited) {
          e2eFailIfRateLimited(AiFailureKind.rateLimit, msg);
        }
        fail('Dream live path failed: $msg');
      }
      expect(controller.phase, DreamJourneyPhase.complete);
      expect(repo._items, isNotEmpty);
    } else {
      expect(controller.phase, DreamJourneyPhase.error);
      expect(controller.errorMessage, ResilienceCopy.aiConfigMissing);
      expect(repo._items, isEmpty);
      await controller.loadHistory();
      expect(controller.history, isEmpty);
    }
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('Dream insight mapper keeps required structured fields', () {
    final insights = DreamAiInsightMapper.map(
      analysis: const DreamAiAnalysis(
        summary: 'Ruya sakin bir gecis hissi tasiyor.',
        symbols: ['yilan'],
        emotionalTheme: 'Belirsizlik ve yenilenme hissi.',
        interpretation: 'Yilan burada bir donusum izi olabilir.',
        dailyLifeReflection: 'Bugun acele etmeden bir adim geri dur.',
        conclusion: 'Bu ruya bir uyari degil, bir davettir.',
      ),
      dream: Dream(
        id: 'map',
        narrative: 'Ruyamda uzun bir yilan evden gecti.',
        recordedAt: DateTime(2026, 8, 18),
        understanding: DreamUnderstandingService().build(
          narrative: 'Ruyamda uzun bir yilan evden gecti.',
        ),
      ),
      understanding: DreamUnderstandingService().build(
        narrative: 'Ruyamda uzun bir yilan evden gecti.',
      ),
    );
    expect(insights.map((i) => i.kind), containsAll([
      DreamInsightKind.summary,
      DreamInsightKind.symbols,
      DreamInsightKind.emotionalMeaning,
      DreamInsightKind.closingTakeaway,
    ]));
  });

  test('Coffee vision hits proxy and does not invent a reading', () async {
    final probe = AiE2eProbe();
    final analysis = OpenAiCoffeeAnalysis(ai: e2eLiveAi(probe));
    expect(analysis.isAvailable, isTrue);
    if (e2eProviderConfigured) {
      try {
        final reading = await analysis.analyze(
          CoffeeImagePick(
            path: 'lib/assets/images/coffee_ritual_hero.webp',
            mimeType: 'image/webp',
          ),
        );
        expect(reading.overall.trim(), isNotEmpty);
      } on CoffeeAnalysisException catch (e) {
        if (e.message == ResilienceCopy.aiRateLimited) {
          e2eFailIfRateLimited(AiFailureKind.rateLimit, e.message);
        }
        rethrow;
      }
    } else {
      try {
        await analysis.analyze(
          CoffeeImagePick(
            path: 'lib/assets/images/coffee_ritual_hero.webp',
            mimeType: 'image/webp',
          ),
        );
        fail('must not fabricate coffee vision');
      } on CoffeeAnalysisException catch (e) {
        if (e.message == ResilienceCopy.aiRateLimited) {
          e2eFailIfRateLimited(AiFailureKind.rateLimit, e.message);
        }
        expect(e.message, ResilienceCopy.aiConfigMissing);
      }
    }
    expect(jsonDecode(probe.lastBody!)['operation'], 'coffee_analysis');
    expect(probe.lastUrl.host, isNot('api.openai.com'));
    expect(probe.lastBody, isNot(contains('sk-')));
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('unavailable coffee vision stays honest', () {
    expect(const UnavailableCoffeeAnalysis().isAvailable, isFalse);
    expect(
      () => const UnavailableCoffeeAnalysis().analyze(
        CoffeeImagePick(path: 'missing.jpg'),
      ),
      throwsA(
        isA<CoffeeAnalysisException>().having(
          (e) => e.message,
          'message',
          CoffeeCopy.analysisUnavailable,
        ),
      ),
    );
  });

  test('Coffee OR context does not leak tarot cards', () {
    final coffee = OracleReadingContextSources.coffee(
      CoffeeReading(
        id: 'c1',
        createdAt: DateTime.fromMillisecondsSinceEpoch(0),
        overall: 'Fincan sakin bir duruluk hissi tasiyor.',
        love: 'Iliskide yumusak bir nefes alani var.',
        career: 'Iste acele etmeden ilerlemek iyi gelir.',
        money: 'Maddi konularda olculu kalmak faydali olabilir.',
        nearFuture: 'Yakin donemde sakin bir tempo uygun.',
        takeaway: 'Bugun biraz daha yavas olmak iyi gelir.',
        visualObservation: 'Ince daginik izler gorunuyor.',
      ),
    );
    expect(coffee.kind.name, 'coffee');
    expect(coffee.cardsSummary, isNot(contains('The Moon')));
    expect(coffee.fullInterpretation, contains('Görülen:'));
    expect(coffee.fullInterpretation, contains('Kariyer:'));
    expect(coffee.fullInterpretation, isNot(contains('The Moon')));
    expect(coffee.fullInterpretation, isNot(contains('Üç Kart')));
  });
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
  Future<void> delete(String id) async => _items.removeWhere((e) => e.id == id);

  @override
  Future<void> sync() async {}
}
