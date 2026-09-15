import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/ai_request_guard.dart';
import 'package:oracly_new/features/ai/production/ai_runtime_config.dart';
import 'package:oracly_new/features/ai/production/openai/openai_image_analysis.dart';
import 'package:oracly_new/features/ai/production/transport/ai_proxy_request.dart';
import 'package:oracly_new/features/ai/production/transport/ai_transport.dart';

class _BridgeTransport implements AiTransport {
  _BridgeTransport(this.themes, this.finalData);

  final List<String> themes;
  final Map<String, dynamic> finalData;
  final List<AiProxyRequest> requests = [];

  @override
  Future<AiOutcome<Map<String, dynamic>>> execute(AiProxyRequest request) async {
    requests.add(request);
    return AiOutcome.success(
      request.payload['readingPhase'] == 'observe'
          ? {'readingPhase': 'observed', 'relevantThemes': themes}
          : finalData,
    );
  }
}

const _coffeeResult = <String, dynamic>{
  'visualObservation': 'Visible residue follows two clear paths.',
  'overall': 'The two visible paths suggest a choice that can be considered calmly.',
  'love': '',
  'career': '',
  'money': '',
  'nearFuture': '',
  'takeaway': 'Consider one path at a time.',
  'symbols': <Object>[],
};

const _palmResult = <String, dynamic>{
  'visualObservation': 'The major palm lines are clearly visible.',
  'overall': 'The visible lines have distinct and continuous paths.',
  'lifeLine': 'A continuous arc is visible.',
  'headLine': 'A straight line is visible.',
  'heartLine': 'A curved upper line is visible.',
  'fateLine': '',
  'takeaway': 'Notice the contrast between the paths.',
};

void main() {
  late List<int> imageBytes;
  setUp(() {
    AiRequestGuard.shared.reset();
    imageBytes = File('lib/assets/images/coffee_ritual_hero.webp').readAsBytesSync();
  });

  OpenAiImageAnalysis analysis(_BridgeTransport transport) => OpenAiImageAnalysis(
        config: const AiRuntimeConfig(proxyUrl: 'http://127.0.0.1:8787'),
        transport: transport,
        guard: AiRequestGuard.shared,
      );

  test('Coffee retrieves after evidence and injects attributed matching memory', () async {
    final transport = _BridgeTransport(['decision'], _coffeeResult);
    final outcome = await analysis(transport).coffeeWithEvidenceMemory(
      imageBytes: imageBytes,
      mimeType: 'image/webp',
      basePersonalization: const {'firstName': 'Fatih'},
      memorySummary: (themes) {
        expect(themes, ['decision']);
        return '[tarot | 2026-09-07 | t1] An earlier decision remained open.';
      },
    );
    expect(outcome.isSuccess, isTrue);
    expect(transport.requests, hasLength(2));
    expect(transport.requests.first.payload.containsKey('personalization'), isFalse);
    final sent = transport.requests.last.payload['personalization'] as Map<String, dynamic>;
    expect(sent['relevantThemes'], ['decision']);
    expect(sent['memorySummary'], contains('[tarot | 2026-09-07 | t1]'));
    expect(transport.requests.last.payload.containsKey('imageBase64'), isFalse);
  });

  test('Coffee with no usable theme skips memory retrieval', () async {
    final transport = _BridgeTransport(const [], _coffeeResult);
    var retrievals = 0;
    final outcome = await analysis(transport).coffeeWithEvidenceMemory(
      imageBytes: imageBytes,
      mimeType: 'image/webp',
      basePersonalization: null,
      memorySummary: (_) { retrievals++; return 'must not be used'; },
    );
    expect(outcome.isSuccess, isTrue);
    expect(retrievals, 0);
    expect(transport.requests.last.payload.containsKey('personalization'), isFalse);
  });

  test('Palm memory failure is soft and writer still executes', () async {
    final transport = _BridgeTransport(['relationship'], _palmResult);
    final outcome = await analysis(transport).palmWithEvidenceMemory(
      imageBytes: imageBytes,
      mimeType: 'image/webp',
      hand: 'right',
      basePersonalization: null,
      memorySummary: (_) => throw StateError('offline memory'),
    );
    expect(outcome.isSuccess, isTrue);
    expect(transport.requests, hasLength(2));
    final sent = transport.requests.last.payload['personalization'] as Map<String, dynamic>;
    expect(sent['relevantThemes'], ['relationship']);
    expect(sent.containsKey('memorySummary'), isFalse);
  });
}
