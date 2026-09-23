/// Phase 3D.1C red-team — safety firewall + no prose parsing.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final files = [
    'lib/features/tarot/narrative/evidence/narrative_relationship_context.dart',
    'lib/features/tarot/narrative/evidence/narrative_relationship_rules.dart',
    'lib/features/tarot/narrative/evidence/narrative_relationship_candidate.dart',
    'lib/features/tarot/narrative/evidence/narrative_relationship_scorer.dart',
    'lib/features/tarot/narrative/evidence/narrative_relationship_selector.dart',
    'lib/features/tarot/narrative/evidence/narrative_relationship_guards.dart',
    'lib/features/tarot/narrative/evidence/narrative_relationship_pairing.dart',
    'lib/features/tarot/narrative/evidence/narrative_relationship_kind_resolver.dart',
    'lib/features/tarot/narrative/evidence/narrative_relationship_signals.dart',
    'lib/features/tarot/narrative/evidence/narrative_relationship_ranking.dart',
  ];

  test('forbidden imports / prose fields absent', () {
    final forbidden = [
      'http',
      'dio',
      'firebase',
      'SharedPreferences',
      'HistoryService',
      'JourneyPersonalizationHints',
      'InterpretationEngine',
      'Random',
      'DateTime.now',
      'L10nTriple',
      'coreMeaning',
      'relationshipDynamic',
      'decisionDynamic',
      'actionDirection',
      'orientationExpression',
      'cheating',
      'partnerIsJealous',
      'criminality',
      'mentalIllness',
      'pregnancy',
      'destinedPartner',
      'mindReadingClaim',
      'guaranteedOutcome',
    ];
    for (final path in files) {
      final text = File(path).readAsStringSync();
      for (final bad in forbidden) {
        expect(
          text.contains(bad),
          isFalse,
          reason: '$path must not contain $bad',
        );
      }
      // Prose field names as identifiers — allow keyword id `fear` but not `.fear`
      expect(text.contains('.light'), isFalse);
      expect(text.contains('.shadow'), isFalse);
      expect(text.contains('.tension'), isFalse);
      expect(text.contains('.desire'), isFalse);
    }
  });
}
