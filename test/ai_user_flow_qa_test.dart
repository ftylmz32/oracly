/// Real AI user-flow QA against local Fastify. Plain tests only (real HTTP).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/config/app_environment.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import 'package:oracly_new/features/ai/oracle_conversation/services/oracle_ai_message_source.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_request_exception.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/contexts/oracle_context_mapper.dart';
import 'package:oracly_new/features/ai/production/transport/ai_transport_selection.dart';
import 'package:oracly_new/features/ai/production/transport/direct_openai_transport.dart';
import 'package:oracly_new/features/ai/production/transport/proxy_ai_transport.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/companion/services/companion_ai_bridge.dart';

import 'support/ai_e2e_probe.dart';

bool get _live => Platform.environment['ORACLY_E2E'] == '1';

void main() {
  final skip = _live ? false : 'Set ORACLY_E2E=1 with local Fastify running';

  setUpAll(() async {
    if (_live) await detectE2eProvider();
  });

  test('Sohbet live path hits proxy only and stays Turkish', () async {
    final probe = AiE2eProbe();
    final bridge = CompanionAiBridge(e2eLiveAi(probe));
    expect(bridge.isConfigured, isTrue);
    if (e2eProviderConfigured) {
      try {
        final text = await bridge.tryLive(
          userMessage: 'Merhaba, bugun nasilsin?',
        );
        expect(text, isNotNull);
        expect(text!.trim().length, greaterThan(5));
      } on AiRequestException catch (e) {
        e2eFailIfRateLimited(e.failure.kind, e.userMessage);
        rethrow;
      }
    } else {
      try {
        await bridge.tryLive(userMessage: 'Merhaba, bugun nasilsin?');
        fail('must not fabricate a successful chat');
      } on AiRequestException catch (e) {
        e2eFailIfRateLimited(e.failure.kind, e.userMessage);
        expect(e.failure.kind, AiFailureKind.noConfiguration);
        expect(e.userMessage, ResilienceCopy.aiConfigMissing);
        assertCleanError(e.userMessage);
      }
    }
    assertProxyOnly(probe, forbidden: 'sk-SHOULD-NOT-BE-SENT');
    expect(jsonDecode(probe.lastBody!)['operation'], 'chat');
  }, skip: skip, timeout: const Timeout(Duration(minutes: 2)));

  test('OR a Sor kinds stay isolated through the live source', () async {
    final probe = AiE2eProbe();
    final source = OracleAiMessageSource(ai: e2eLiveAi(probe));
    final contexts = [
      const OracleReadingContext(
        sessionId: 'qa-tarot',
        kind: OracleReadingKind.tarot,
        spreadLabel: 'Tek kart',
        deckId: 'rider-waite',
        deckName: 'Rider-Waite',
        readingTitle: 'The Moon',
        cardsSummary: 'The Moon',
        interpretationSummary: 'Sis ve sezgi.',
      ),
      OracleReadingContextSources.dream(
        id: 'qa-dream',
        narrative: 'Ruyamda sessiz bir deniz kenarinda yurudum.',
        analysis: 'Sakin bir gecis hissi.',
      ),
      OracleReadingContextSources.astrology(
        id: 'qa-astro',
        signLabel: 'Yengec',
        daily: 'Bugun yumusak bir tempo uygun.',
      ),
      OracleReadingContextSources.birthChart(
        id: 'qa-birth',
        sunLabel: 'Aslan',
        interpretation: 'Gunes ifadesi sicak ve duru.',
      ),
      OracleReadingContextSources.coffee(
        CoffeeReading(
          id: 'qa-coffee',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          overall: 'Fincan sakin bir duruluk hissi tasiyor.',
          love: 'Iliskide yumusak bir nefes alani var.',
          career: 'Iste acele etmeden ilerlemek iyi gelir.',
          money: 'Maddi konularda olculu kalmak faydali olabilir.',
          nearFuture: 'Yakin donemde sakin bir tempo uygun.',
          takeaway: 'Bugun biraz daha yavas olmak iyi gelir.',
        ),
      ),
    ];

    for (final ctx in contexts) {
      if (e2eProviderConfigured) {
        try {
          final text = await source.reply(
            context: ctx,
            userMessage: 'Bu okuma ne anlatiyor?',
          );
          expect(text.trim().length, greaterThan(5));
        } on AiRequestException catch (e) {
          e2eFailIfRateLimited(e.failure.kind, e.userMessage);
          rethrow;
        }
      } else {
        try {
          await source.reply(
            context: ctx,
            userMessage: 'Bu okuma ne anlatiyor?',
          );
          fail('must not fabricate oracle copy for ${ctx.kind}');
        } on AiRequestException catch (e) {
          e2eFailIfRateLimited(e.failure.kind, e.userMessage);
          expect(e.userMessage, ResilienceCopy.aiConfigMissing);
        }
      }
    }
    final kinds = [
      for (final body in probe.bodies)
        (jsonDecode(body) as Map)['payload']['context']['kind'],
    ];
    expect(kinds, ['tarot', 'dream', 'astrology', 'birthChart', 'coffee']);
    expect(probe.bodies[0], contains('The Moon'));
    expect(probe.bodies[1], isNot(contains('The Moon')));
    expect(OracleContextMapper.fromOracle(contexts[0]).kindId, 'tarot');
    expect(OracleContextMapper.fromOracle(contexts[1]).kindId, 'dream');
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));

  test('production proxy routing never uses DirectOpenAi', () {
    const config = AiRuntimeConfig(
      environment: AppEnvironment.production,
      proxyUrl: 'https://api.oracly.app/v1/ai/complete',
      openAiKey: 'sk-SHOULD-NOT-BE-SENT',
    );
    expect(AiTransportSelection.create(config), isA<ProxyAiTransport>());
    expect(
      AiTransportSelection.create(config),
      isNot(isA<DirectOpenAiTransport>()),
    );
    const bare = AiRuntimeConfig(
      environment: AppEnvironment.production,
      openAiKey: 'sk-SHOULD-NOT-BE-SENT',
    );
    expect(AiTransportSelection.create(bare), isNull);
  });
}
