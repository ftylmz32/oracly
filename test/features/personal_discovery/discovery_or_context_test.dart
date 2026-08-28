/// Phase 8 — OR cites themes only when they really exist.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/openai/openai_service_requests.dart';
import 'package:oracly_new/features/personal_discovery/copy/personal_theme_copy.dart';
import 'package:oracly_new/features/personal_discovery/services/discovery_or_context.dart';

void main() {
  test('empty themes never invent a past', () {
    expect(DiscoveryOrContext.line(const []), isNull);
    expect(DiscoveryOrContext.mergeHint('Nazik ol.', const []), 'Nazik ol.');
    expect(DiscoveryOrContext.mergeHint('', const []), isEmpty);
  });

  test('real themes stay observational and never diagnose', () {
    final line = DiscoveryOrContext.line(const ['sınırlar', 'değişim']);
    expect(line, contains(PersonalThemeCopy.recurring(const ['sınırlar', 'değişim'])));
    expect(line!.toLowerCase(), isNot(contains('sen şöylesin')));
    expect(line.toLowerCase(), contains('uydurma'));
  });

  test('oracle payload includes themes without uid or secrets', () {
    final request = OpenAiServiceRequests.oracle(
      model: 'gpt-test',
      context: const AstrologyAiContext(
        signLabel: 'Koç',
        daily: 'Bugün sakin ilerle.',
      ),
      userMessage: 'Son zamanlarda neden hep aynı şeyleri yaşıyorum?',
      priorUser: const [],
      observedThemes: const ['sınırlar'],
    );
    final ctx = request.payload['context'] as Map<String, dynamic>;
    expect(ctx['observedThemes'], ['sınırlar']);
    expect(request.payload.containsKey('userId'), isFalse);
    expect(request.payload.containsKey('uid'), isFalse);
    expect(jsonBlob(request.payload), isNot(contains('sk-')));
    expect(jsonBlob(request.payload), isNot(contains('Bearer')));
  });

  test('oracle payload omits observedThemes when none exist', () {
    final request = OpenAiServiceRequests.oracle(
      model: 'gpt-test',
      context: const AstrologyAiContext(
        signLabel: 'Koç',
        daily: 'Bugün sakin ilerle.',
      ),
      userMessage: 'Nasılsın?',
      priorUser: const [],
    );
    final ctx = request.payload['context'] as Map<String, dynamic>;
    expect(ctx.containsKey('observedThemes'), isFalse);
  });
}

String jsonBlob(Map<String, dynamic> payload) => payload.toString();
