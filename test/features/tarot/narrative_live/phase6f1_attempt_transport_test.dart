/// Phase 6F.1 — attempt-specific AiRequestGuard + real second transport execute.
/// REAL PROVIDER CALLS = 0.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/ai_request_guard.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/openai/openai_oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/transport/ai_proxy_request.dart';
import 'package:oracly_new/features/ai/production/transport/ai_transport.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_binder.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_attempt.dart';

class _CountingTransport implements AiTransport {
  final executes = <AiProxyRequest>[];

  @override
  Future<AiOutcome<Map<String, dynamic>>> execute(AiProxyRequest request) async {
    executes.add(request);
    return AiOutcome.success({
      'contractVersion': 2,
      'languageCode': 'en',
      'summary': 'ok ${executes.length}',
    });
  }
}

void main() {
  late AiRequestGuard guard;
  late _CountingTransport transport;
  late OpenAiOraclyAiService ai;

  setUp(() {
    guard = AiRequestGuard();
    transport = _CountingTransport();
    ai = OpenAiOraclyAiService(
      config: const AiRuntimeConfig(
        openAiKey: 'sk-test',
        proxyUrl: 'https://example.test/v1/ai/complete',
      ),
      transport: transport,
      guard: guard,
    );
  });

  const fingerprint = 'tarot-narrative:sem-fp-6f1';
  final payload = <String, dynamic>{
    'mode': 'narrative_v2',
    'contractVersion': 1,
  };

  test('attempt2 is not blocked by attempt1 lastOk — transport.execute = 2',
      () async {
    await PaidAiOperationBinder.runWithKey('paid-base-6f1', () async {
      final a1 = await ai.generateNarrativeTarotReading(
        payload: payload,
        fingerprint: fingerprint,
        attempt: 1,
      );
      expect(a1.isSuccess, isTrue);

      final a2 = await ai.generateNarrativeTarotReading(
        payload: payload,
        fingerprint: fingerprint,
        attempt: 2,
      );
      expect(a2.isSuccess, isTrue);
    });

    expect(transport.executes, hasLength(2));
    expect(transport.executes[0].idempotencyKey, 'paid-base-6f1:nv2:a1');
    expect(transport.executes[1].idempotencyKey, 'paid-base-6f1:nv2:a2');
    expect(
      transport.executes[0].idempotencyKey,
      isNot(transport.executes[1].idempotencyKey),
    );
    expect(
      NarrativeTarotAttempt.guardKey(fingerprint, 1),
      isNot(NarrativeTarotAttempt.guardKey(fingerprint, 2)),
    );
    expect(
      transport.executes[0].idempotencyKey!.endsWith(':nv2:a1'),
      isTrue,
    );
    expect(
      transport.executes[1].idempotencyKey!.endsWith(':nv2:a2'),
      isTrue,
    );
    expect(
      transport.executes[0].idempotencyKey!.startsWith('paid-base-6f1'),
      isTrue,
    );
  });

  test('same attempt still coalesces / duplicate-protects', () async {
    await PaidAiOperationBinder.runWithKey('paid-base-6f1b', () async {
      final first = await ai.generateNarrativeTarotReading(
        payload: payload,
        fingerprint: fingerprint,
        attempt: 1,
      );
      expect(first.isSuccess, isTrue);
      final second = await ai.generateNarrativeTarotReading(
        payload: payload,
        fingerprint: fingerprint,
        attempt: 1,
      );
      // Within tarot duplicate window — rate limited, no second transport.
      expect(second.isFailure, isTrue);
    });
    expect(transport.executes, hasLength(1));
  });

  test('attempt 0 / 3 fail closed', () async {
    await expectLater(
      () => ai.generateNarrativeTarotReading(
        payload: payload,
        fingerprint: fingerprint,
        attempt: 0,
      ),
      throwsA(isA<ArgumentError>()),
    );
    await expectLater(
      () => ai.generateNarrativeTarotReading(
        payload: payload,
        fingerprint: fingerprint,
        attempt: 3,
      ),
      throwsA(isA<ArgumentError>()),
    );
    expect(transport.executes, isEmpty);
  });
}
