/// Phase 6E.6 — offline precall dump for Manifest V2 provider shadow QA.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_request.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';
import 'package:oracly_new/features/tarot/narrative/transport/narrative_tarot_wire_contract.dart';

import '../narrative_prompt/narrative_prompt_test_support.dart';
import '../narrative_result/phase6e3_enrich_support.dart';

const _outPath =
    'test/fixtures/tarot_narrative_provider_shadow_payloads_6e6_v2.json';
const _manifestPath =
    'test/fixtures/tarot_narrative_provider_shadow_manifest_v2.json';
const _qaRunHead = '8a33915e0462438f21c3b74c0d6fd7f787c78730';

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
  test('6E.6 precall dump — all six Manifest V2 payloads valid offline', () {
    final manifest =
        jsonDecode(File(_manifestPath).readAsStringSync()) as Map;
    expect(manifest['entryCount'], 6);
    expect(manifest['version'], 2);
    expect(manifest['resultContractVersion'], 2);
    expect(manifest['providerSchemaName'], 'oracly_tarot_narrative_v2');
    final entries = (manifest['entries'] as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    expect(entries.length, 6);

    final dumped = <Map<String, dynamic>>[];
    for (final entry in entries) {
      final id = entry['manifestId'] as String;
      final lang = entry['languageCode'] as String;
      final TarotNarrativeRequest request;
      final Map<String, Object?> wire;

      final evidenceId = entry['evidenceScenarioId'] as String?;
      final harness = entry['harness'] as String?;
      if (harness == 'enrichedProviderQaRequest') {
        request = enrichedProviderQaRequest();
        expect(request.languageCode, lang, reason: id);
        expect(request.cards.first.displayName, isNot('major_00'), reason: id);
        expect(request.memory.included, isTrue, reason: id);
        expect(request.memory.entries.length, greaterThanOrEqualTo(2),
            reason: id);
        expect(request.recurringCards, isNotEmpty, reason: id);
        expect(request.spread.spreadId.startsWith('classical.'), isTrue,
            reason: id);
        expect(request.question.hasRealQuestion, isTrue, reason: id);
      } else if (evidenceId != null) {
        request = buildFromCorpusId(evidenceId);
        expect(request.languageCode, lang, reason: id);
        expect(entry['spreadType'], request.spread.legacyTypeName, reason: id);
      } else {
        fail('$id: no evidenceScenarioId or enriched harness');
      }

      final input = NarrativeTarotPromptSerializer.serialize(request);
      wire = NarrativeTarotWireContract.payloadFor(input);
      expect(wire['mode'], 'narrative_v2');
      expect(wire['contractVersion'], 1);
      expect(wire['language'], lang);

      final encoded = jsonEncode(wire);
      for (final n in _privacyNeedles) {
        if (n == 'mem_') {
          expect(RegExp(r'\bmem_').hasMatch(encoded), isFalse,
              reason: '$id privacy $n');
        } else if (n.endsWith('_')) {
          expect(encoded.contains(n), isFalse, reason: '$id privacy $n');
        } else {
          expect(RegExp('"\\s*$n\\s*"\\s*:').hasMatch(encoded), isFalse,
              reason: '$id privacy key $n');
        }
      }

      final memory = request.memory;
      dumped.add({
        'manifestId': id,
        'languageCode': lang,
        'spreadType': entry['spreadType'],
        'resolvedSpreadId': request.spread.spreadId,
        'cardCount': request.cards.length,
        'evidenceScenarioId': evidenceId,
        'harness': harness,
        'displayName': request.cards.first.displayName,
        'memoryIncluded': memory.included,
        'memoryEntryCount': memory.entries.length,
        'recurringCardCount': request.recurringCards.length,
        'recurringThemeCount': request.recurringThemes.length,
        'relationshipCount': request.relationships.length,
        'questionKind': request.question.kind.name,
        'hasRealQuestion': request.question.hasRealQuestion,
        'questionText': request.question.rawText,
        'resultContractTarget': 2,
        'providerSchemaName': 'oracly_tarot_narrative_v2',
        'memorySummariesForQa': [
          for (var i = 0; i < memory.entries.length; i++)
            {
              'index': i,
              'kind': memory.entries[i].kind.name,
              'sourceType': memory.entries[i].sourceType,
              'contentForModel': memory.entries[i].contentForModel,
            },
        ],
        'wirePayload': wire,
      });
    }

    final out = {
      'qaRunHead': _qaRunHead,
      'manifestVersion': manifest['version'],
      'manifestPath': _manifestPath,
      'resultContractVersion': 2,
      'providerSchemaName': 'oracly_tarot_narrative_v2',
      'entryCount': dumped.length,
      'authorizedCallCap': 6,
      'entries': dumped,
    };
    File(_outPath).writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(out),
    );
    expect(File(_outPath).existsSync(), isTrue);
    expect(dumped.length, 6);
  });
}
