/// Phase 6E.2 — offline precall dump for authorized provider shadow QA.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';
import 'package:oracly_new/features/tarot/narrative/transport/narrative_tarot_wire_contract.dart';

import '../narrative_prompt/narrative_prompt_test_support.dart';

const _outPath =
    'test/fixtures/tarot_narrative_provider_shadow_payloads_6e2.json';
const _manifestPath =
    'test/fixtures/tarot_narrative_provider_shadow_manifest_v1.json';

const _privacyNeedles = [
  'sessionId',
  'readingId',
  'ownerId',
  'evidenceId',
  'sourceId',
  'supportingReadingIds',
  'rel_',
  'rec_card_',
  'rec_theme_',
  'mem_',
];

void main() {
  test('6E.2 precall dump — all six payloads valid offline', () {
    final manifest =
        jsonDecode(File(_manifestPath).readAsStringSync()) as Map;
    expect(manifest['entryCount'], 6);
    expect(manifest['version'], 1);
    final entries = (manifest['entries'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    expect(entries.length, 6);

    final promptFx = loadPromptFixture();
    final scenarios = (promptFx['scenarios'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final dumped = <Map<String, dynamic>>[];
    for (final entry in entries) {
      final id = entry['manifestId'] as String;
      final lang = entry['languageCode'] as String;
      final TarotNarrativeRequest request;
      final Map<String, Object?> wire;
      final String spreadId;
      final int cardCount;

      final evidenceId = entry['evidenceScenarioId'] as String?;
      final promptId = entry['promptFixtureScenarioId'] as String?;
      if (evidenceId != null) {
        request = buildFromCorpusId(evidenceId);
        expect(request.languageCode, lang, reason: id);
        final input = NarrativeTarotPromptSerializer.serialize(request);
        wire = NarrativeTarotWireContract.payloadFor(input);
        spreadId = request.spread.spreadId;
        cardCount = request.cards.length;
        expect(entry['spreadType'], request.spread.legacyTypeName, reason: id);
      } else if (promptId != null) {
        final scen = scenarios.firstWhere((s) => s['id'] == promptId);
        final modelInput =
            Map<String, dynamic>.from(scen['modelInput'] as Map);
        request = enrichedForSerialize();
        wire = <String, Object?>{
          'mode': NarrativeTarotWireContract.mode,
          'contractVersion': NarrativeTarotWireContract.contractVersion,
          'language': modelInput['languageCode'],
          'narrative': modelInput,
        };
        final spread = Map<String, dynamic>.from(modelInput['spread'] as Map);
        spreadId = spread['spreadId'] as String;
        cardCount = (modelInput['cards'] as List).length;
        expect(lang, modelInput['languageCode'], reason: id);
      } else {
        fail('$id: no evidenceScenarioId or promptFixtureScenarioId');
      }

      expect(wire['mode'], 'narrative_v2');
      expect(wire['contractVersion'], 1);
      expect(wire['language'], lang);
      final encoded = jsonEncode(wire);
      for (final n in _privacyNeedles) {
        // Keys like "memory" / "memoryInsights" contain no mem_ token;
        // forbid mem_ as an id prefix only.
        if (n == 'mem_') {
          expect(
            RegExp(r'\bmem_').hasMatch(encoded),
            isFalse,
            reason: '$id privacy $n',
          );
        } else if (n.endsWith('_')) {
          expect(encoded.contains(n), isFalse, reason: '$id privacy $n');
        } else {
          // Avoid false positives on nested field names that are allowed
          // only when they are forbidden top-level identity keys in wire.
          expect(
            RegExp('"\\s*$n\\s*"\\s*:').hasMatch(encoded),
            isFalse,
            reason: '$id privacy key $n',
          );
        }
      }

      dumped.add({
        'manifestId': id,
        'languageCode': lang,
        'spreadType': entry['spreadType'],
        'resolvedSpreadId': spreadId,
        'cardCount': cardCount,
        'evidenceScenarioId': evidenceId,
        'promptFixtureScenarioId': promptId,
        'wirePayload': wire,
        'requestSessionId': request.sessionId,
        'requestReadingId': request.readingId,
      });
    }

    final out = {
      'qaRunHead': '3987f7a7851ba24b27ab58b36d3c0f2c3f04025b',
      'manifestVersion': manifest['version'],
      'manifestPath': _manifestPath,
      'entryCount': dumped.length,
      'authorizedCallCap': 6,
      'entries': dumped,
    };
    File(_outPath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(out),
    );
    expect(File(_outPath).existsSync(), isTrue);
  });
}
