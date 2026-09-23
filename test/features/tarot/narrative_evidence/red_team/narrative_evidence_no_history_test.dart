/// Phase 3D.1D red-team — no history/AI/network imports in builder surface.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final files = [
    'lib/features/tarot/narrative/evidence/narrative_evidence_builder.dart',
    'lib/features/tarot/narrative/evidence/narrative_evidence_input.dart',
    'lib/features/tarot/narrative/evidence/narrative_evidence_validation.dart',
  ];

  test('forbidden imports / history access absent', () {
    final forbidden = [
      'HistoryService',
      'JourneyPersonalizationHints',
      'SharedPreferences',
      'firebase',
      'package:dio',
      'package:http',
      'InterpretationEngine',
      'TarotInterpretationService',
      'Random(',
      'DateTime.now',
    ];
    for (final path in files) {
      final text = File(path).readAsStringSync();
      for (final bad in forbidden) {
        expect(text.contains(bad), isFalse, reason: '$path :: $bad');
      }
    }
  });

  test('builder not referenced outside evidence domain in lib/', () {
    final root = Directory('lib');
    final hits = <String>[];
    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.contains('narrative${Platform.pathSeparator}evidence')) {
        continue;
      }
      final text = entity.readAsStringSync();
      if (text.contains('NarrativeEvidenceBuilder') ||
          text.contains('narrative_evidence_builder.dart')) {
        hits.add(entity.path);
      }
    }
    expect(hits, isEmpty, reason: hits.join(', '));
  });
}
