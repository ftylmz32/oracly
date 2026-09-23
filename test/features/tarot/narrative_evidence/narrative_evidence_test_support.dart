/// Shared helpers for 3D.1D builder / corpus tests.
library;

import 'dart:convert';
import 'dart:io';

import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_input.dart';

Map<String, dynamic> loadEvidenceCorpus() {
  final file = File('test/fixtures/tarot_narrative_evidence_v1.json');
  return jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
}

NarrativeEvidenceInput inputFromScenario(Map<String, dynamic> scenario) {
  final input = scenario['input'] as Map<String, dynamic>;
  final cardsJson = input['cards'] as List<dynamic>;
  return NarrativeEvidenceInput(
    sessionId: input['sessionId'] as String,
    readingId: input['readingId'] as String,
    languageCode: input['languageCode'] as String,
    questionRaw: input['questionRaw'] as String?,
    intentionTopic: input['intentionTopic'] as String?,
    spreadType: TarotSpreadType.values.byName(input['spreadType'] as String),
    cards: [
      for (final c in cardsJson)
        NarrativeEvidenceCardInput(
          canonicalCardId: (c as Map)['canonicalCardId'] as String,
          ritualCardId: c['ritualCardId'] as int,
          isReversed: c['isReversed'] as bool,
          positionKey: c['positionKey'] as String,
          positionIndex: c['positionIndex'] as int,
        ),
    ],
  );
}

final ritualByCanonical = <String, int>{};
