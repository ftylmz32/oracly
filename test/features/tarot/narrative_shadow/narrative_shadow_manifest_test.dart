/// Phase 6E — provider shadow manifest lock (refs only, max 6).
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'narrative_shadow_test_support.dart';

void main() {
  test('provider shadow manifest lock (max 6, refs only)', () {
    final root = jsonDecode(
      File(
        'test/fixtures/tarot_narrative_provider_shadow_manifest_v1.json',
      ).readAsStringSync(),
    ) as Map<String, dynamic>;
    final entries = root['entries'] as List;
    expect(root['entryCount'], entries.length);
    expect(entries.length, lessThanOrEqualTo(6));
    expect(root['realProviderCallsInPhase6E'], 0);
    expect(root['billingAllowed'], isFalse);
    final evidenceIds = {
      for (final s in launchScenarios()) s['id'] as String,
    };
    final promptIds = (jsonDecode(
      File('test/fixtures/tarot_narrative_prompt_v1.json').readAsStringSync(),
    ) as Map)['scenarios'] as List;
    final promptSet = {
      for (final s in promptIds) (s as Map)['id'] as String,
    };
    for (final e in entries) {
      final row = Map<String, dynamic>.from(e as Map);
      final ev = row['evidenceScenarioId'] as String?;
      final pr = row['promptFixtureScenarioId'] as String?;
      expect(ev != null || pr != null, isTrue);
      if (ev != null) expect(evidenceIds.contains(ev), isTrue);
      if (pr != null) expect(promptSet.contains(pr), isTrue);
      expect(row.containsKey('questionText'), isFalse);
      expect(row.containsKey('ownerId'), isFalse);
    }
  });
}
