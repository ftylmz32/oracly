/// Dream Phase 2 — semantic request identity (guard key, duplicate
/// fingerprint, provider replay key). Synthetic inputs, zero provider calls.
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/ai_request_guard.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/dream_request_identity.dart';
import 'package:oracly_new/features/ai/production/openai/openai_oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/openai/openai_paid_requests.dart';
import 'package:oracly_new/features/ai/production/transport/ai_proxy_request.dart';
import 'package:oracly_new/features/ai/production/transport/ai_transport.dart';
import 'package:oracly_new/features/dream/services/dream_context_enricher.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_binder.dart';

const _told = 'Mira ile Leo fenerin yanında, limanda bekliyordu.';

DreamAiContext _ctx({
  String narrative = _told,
  String language = 'tr',
  List<String> symbols = const ['Fener', 'Liman'],
  List<String> emotions = const ['Meraklı'],
  String? memory = 'Mira earlier noted a harbor.',
}) => DreamAiContext(
  narrative: narrative,
  language: language,
  symbols: symbols,
  emotions: emotions,
  memorySummary: memory,
);

String _fp(DreamAiContext c) => DreamRequestIdentity.fingerprint(c);
String? _key(DreamAiContext c) =>
    OpenAiPaidRequests.dream(model: 'm', context: c).idempotencyKey;

class _HeldTransport implements AiTransport {
  final requests = <AiProxyRequest>[];
  final _held = Completer<AiOutcome<Map<String, dynamic>>>();

  @override
  Future<AiOutcome<Map<String, dynamic>>> execute(AiProxyRequest request) {
    requests.add(request);
    return _held.future;
  }

  void failAll() => _held.complete(AiOutcome.failure(AiFailure.network()));
}

void main() {
  tearDown(() => OraclyL10n.bind('tr'));

  group('identity matrix', () {
    final base = _ctx();
    DreamAiContext tagged(List<String> tags) => _ctx(
      narrative: DreamContextEnricher.narrativeForAi(narrative: _told, tags: tags),
    );
    final pairs = <String, (DreamAiContext, DreamAiContext)>{
      'B TR vs EN': (base, _ctx(language: 'en')),
      'C EN vs RU': (_ctx(language: 'en'), _ctx(language: 'ru')),
      'D emotions differ': (base, _ctx(emotions: const ['Korkulu'])),
      'E symbols differ': (base, _ctx(symbols: const ['Fener', 'Kapı'])),
      'F memory differs': (base, _ctx(memory: 'Leo earlier noted a door.')),
      'F memory removed': (base, _ctx(memory: null)),
      'G tag added': (base, tagged(const ['iş'])),
      'G tag changed': (tagged(const ['iş']), tagged(const ['aile'])),
      'narrative differs': (base, _ctx(narrative: '$_told Kapı açıktı.')),
    };

    test('A exact retry is stable (fingerprint and replay key)', () {
      expect(_fp(_ctx()), _fp(base));
      expect(_key(_ctx()), _key(base));
      expect(_fp(tagged(const ['iş'])), _fp(tagged(const ['iş'])));
      expect(_fp(base), startsWith('dream:v1:'));
      expect(_key(base), matches(RegExp(r'^dream-[0-9a-f]{32}$')));
    });

    for (final entry in pairs.entries) {
      test('${entry.key} → new identity', () {
        final (a, b) = entry.value;
        expect(_fp(a), isNot(_fp(b)));
        expect(_key(a), isNot(_key(b)));
      });
    }

    test('H casing, whitespace and set order are an exact retry', () {
      final cosmetic = _ctx(
        narrative: '  MIRA ile   Leo fenerin yanında,\nlimanda bekliyordu. ',
        symbols: const ['liman ', ' FENER', 'fener'],
        emotions: const ['  meraklı'],
        memory: 'mira earlier  noted a HARBOR.',
      );
      expect(_fp(cosmetic), _fp(base));
      expect(_key(cosmetic), _key(base));
    });

    test('unset language uses the app language at send time', () {
      OraclyL10n.bind('en');
      const unset = DreamAiContext(narrative: _told);
      expect(_fp(unset), _fp(const DreamAiContext(narrative: _told, language: 'en')));
    });
  });

  group('paid binder', () {
    test('bound key keeps billing prefix and appends the semantic digest',
        () async {
      final keys = await PaidAiOperationBinder.runWithKey('or-dream-x', () async {
        return [_key(_ctx()), _key(_ctx()), _key(_ctx(language: 'en'))];
      });
      expect(keys[0], matches(RegExp(r'^or-dream-x:ds-[0-9a-f]{32}$')));
      expect(keys[1], keys[0]);
      expect(keys[2], isNot(keys[0]));
      expect(keys[2], startsWith('or-dream-x:ds-'));
    });
  });

  group('client guard', () {
    const config = AiRuntimeConfig(openAiKey: 'test-key');

    test('only an exact semantic retry coalesces in flight', () async {
      final transport = _HeldTransport();
      final ai = OpenAiOraclyAiService(
        config: config,
        transport: transport,
        guard: AiRequestGuard(),
      );
      final calls = [
        ai.analyzeDream(_ctx()),
        ai.analyzeDream(_ctx(narrative: ' MIRA ile leo fenerin yanında, limanda bekliyordu.')),
        ai.analyzeDream(_ctx(language: 'en')),
        ai.analyzeDream(_ctx(emotions: const ['Korkulu'])),
        ai.analyzeDream(_ctx(symbols: const ['Kapı'])),
      ];
      expect(transport.requests, hasLength(4));
      expect(transport.requests.map((r) => r.payload['language']).toSet(),
          {'tr', 'en'});
      transport.failAll();
      final outcomes = await Future.wait(calls);
      expect(outcomes.every((o) => !o.isSuccess), isTrue);
    });
  });
}
