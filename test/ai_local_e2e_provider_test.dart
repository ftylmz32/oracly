/// Real-provider E2E. Skips unless backend already has OPENAI_API_KEY.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';

import 'support/ai_e2e_probe.dart';

bool get _e2e => Platform.environment['ORACLY_E2E'] == '1';

void main() {
  final skip = _e2e ? false : 'Set ORACLY_E2E=1 with local Fastify running';

  setUpAll(() async {
    if (_e2e) await detectE2eProvider();
  });

  test('REAL OR a Sor tarot + dream — isolated context', () async {
    if (e2eProviderBlocker != null) {
      markTestSkipped(e2eProviderBlocker!);
      return;
    }
    final probe = AiE2eProbe();
    final ai = e2eLiveAi(probe);
    final tarotOut = await ai.askOracle(
      context: const TarotAiContext(
        sessionId: 'e2e-tarot',
        spreadLabel: 'Tek kart',
        readingTitle: 'Bugun',
        cardsSummary: 'The Moon',
        interpretationSummary: 'Sis ve sezgi.',
      ),
      userMessage: 'Bu kart bana ne soyluyor?',
    );
    final dreamOut = await ai.askOracle(
      context: const DreamAiContext(
        narrative: 'Ruyamda sessiz bir deniz kenarinda yurudum.',
      ),
      userMessage: 'Bu ruya ne anlatiyor?',
    );
    e2eFailIfRateLimited(tarotOut.failure?.kind, tarotOut.failure?.userMessage);
    e2eFailIfRateLimited(dreamOut.failure?.kind, dreamOut.failure?.userMessage);
    expect(tarotOut.isSuccess, isTrue, reason: '${tarotOut.failure}');
    expect(dreamOut.isSuccess, isTrue, reason: '${dreamOut.failure}');
    final kinds = [
      for (final body in probe.bodies)
        (jsonDecode(body) as Map)['payload']['context']['kind'],
    ];
    expect(kinds, ['tarot', 'dream']);
    expect(probe.bodies[0], contains('The Moon'));
    expect(probe.bodies[1], isNot(contains('The Moon')));
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));

  test('REAL dream analysis returns all structured fields', () async {
    if (e2eProviderBlocker != null) {
      markTestSkipped(e2eProviderBlocker!);
      return;
    }
    final probe = AiE2eProbe();
    final result = await e2eLiveAi(probe).analyzeDream(
      const DreamAiContext(
        narrative: 'Ruyamda uzun bir yilan evden gecti ve sessizce gitti.',
        symbols: ['yilan'],
      ),
    );
    e2eFailIfRateLimited(result.failure?.kind, result.failure?.userMessage);
    expect(result.isSuccess, isTrue, reason: '${result.failure}');
    expect(result.value!.summary.trim(), isNotEmpty);
    expect(result.value!.emotionalTheme.trim(), isNotEmpty);
    expect(result.value!.interpretation.trim(), isNotEmpty);
    expect(result.value!.dailyLifeReflection.trim(), isNotEmpty);
    expect(result.value!.conclusion.trim(), isNotEmpty);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('REAL coffee vision via proxy', () async {
    if (e2eProviderBlocker != null) {
      markTestSkipped(e2eProviderBlocker!);
      return;
    }
    final bytes =
        File('lib/assets/images/coffee_ritual_hero.webp').readAsBytesSync();
    final probe = AiE2eProbe();
    final result = await e2eLiveAi(probe).analyzeCoffee(
      imageBytes: bytes,
      mimeType: 'image/webp',
    );
    e2eFailIfRateLimited(result.failure?.kind, result.failure?.userMessage);
    expect(result.isSuccess, isTrue, reason: '${result.failure}');
    expect(result.value!.visualObservation.trim(), isNotEmpty);
    expect(jsonDecode(probe.lastBody!)['operation'], 'coffee_analysis');
    expect(probe.lastUrl.host, isNot('api.openai.com'));
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}
