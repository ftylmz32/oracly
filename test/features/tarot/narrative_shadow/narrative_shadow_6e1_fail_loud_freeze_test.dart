/// Phase 6E.1 — fail-loud catch contract + deep wire immutability.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/interpretation/models/reading_context.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_shadow_pipeline.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_shadow_status.dart';
import 'package:oracly_new/features/tarot/narrative/transport/narrative_tarot_wire_contract.dart';

import 'narrative_shadow_test_support.dart';

void main() {
  test('shadow pipeline source has no broad on Object / catch (_)', () {
    final src = File(
      'lib/features/tarot/narrative/shadow/'
      'narrative_tarot_shadow_pipeline.dart',
    ).readAsStringSync();
    expect(src.contains('on Object'), isFalse);
    expect(src.contains('catch (_)'), isFalse);
    expect(src.contains('on ArgumentError'), isTrue);
  });

  test('ArgumentError maps to serializationFailed; StateError propagates', () {
    final scenario = launchScenarios().first;
    final session = sessionFromEvidence(scenario);
    final legacy = ReadingContext.fromSession(session, language: 'en');
    final mapped = NarrativeTarotShadowPipeline.mapCaughtError(
      ArgumentError('contract'),
      legacy,
    );
    expect(mapped.status, NarrativeTarotShadowStatus.serializationFailed);
    expect(
      () => NarrativeTarotShadowPipeline.mapCaughtError(
        StateError('invariant'),
        legacy,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('wire payload is deeply immutable without content drift', () {
    final scenario = launchScenarios().firstWhere(
      (s) => s['id'] == 'three_contrast_exemplar_en',
    );
    final result = evaluateScenario(scenario);
    expect(result.isPass, isTrue);
    final wire = result.wirePayload!;
    final before = jsonEncode(wire);

    expect(() => wire['mode'] = 'x', throwsUnsupportedError);
    final narrative = wire['narrative']! as Map<String, Object?>;
    expect(() => narrative['languageCode'] = 'tr', throwsUnsupportedError);
    final cards = narrative['cards']! as List<Object?>;
    expect(() => cards.add(<String, Object?>{}), throwsUnsupportedError);
    final card0 = cards.first! as Map<String, Object?>;
    expect(
      () => card0['canonicalCardId'] = 'mutated',
      throwsUnsupportedError,
    );
    final spread = narrative['spread']! as Map<String, Object?>;
    final positions = spread['positions']! as List<Object?>;
    expect(() => positions.add(<String, Object?>{}), throwsUnsupportedError);
    final rels = narrative['relationships']! as List<Object?>;
    expect(() => rels.add(<String, Object?>{}), throwsUnsupportedError);
    final policy = narrative['policy']! as Map<String, Object?>;
    final rules = policy['rules']! as List<Object?>;
    expect(() => rules.add('x'), throwsUnsupportedError);

    expect(jsonEncode(wire), before);
    expect(
      before,
      jsonEncode(
        NarrativeTarotWireContract.payloadFor(result.promptInput!),
      ),
    );
  });
}
