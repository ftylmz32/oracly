/// Phase 6E — shared corpus / session helpers for Classical shadow tests.
library;

import 'dart:convert';
import 'dart:io';

import 'package:oracly_new/features/tarot/deck/oracly_tarot_bridge.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/models/tarot_card.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_classical_shadow.dart';
import 'package:oracly_new/features/tarot/narrative/shadow/narrative_tarot_shadow_result.dart';

Map<String, dynamic> loadEvidenceCorpus() {
  final raw = File(
    'test/fixtures/tarot_narrative_evidence_v1.json',
  ).readAsStringSync();
  return jsonDecode(raw) as Map<String, dynamic>;
}

List<Map<String, dynamic>> evidenceScenarios() {
  final root = loadEvidenceCorpus();
  return (root['scenarios'] as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
}

bool isLaunchSpread(String spreadType) =>
    spreadType == 'single' ||
    spreadType == 'threeCard' ||
    spreadType == 'fiveCard';

List<Map<String, dynamic>> launchScenarios() =>
    evidenceScenarios().where((s) {
      final input = Map<String, dynamic>.from(s['input'] as Map);
      return isLaunchSpread(input['spreadType'] as String);
    }).toList();

List<Map<String, dynamic>> nonLaunchScenarios() =>
    evidenceScenarios().where((s) {
      final input = Map<String, dynamic>.from(s['input'] as Map);
      final t = input['spreadType'] as String;
      return t == 'sevenCard' || t == 'celticCross';
    }).toList();

TarotSpreadType spreadTypeNamed(String name) =>
    TarotSpreadType.values.firstWhere((t) => t.name == name);

TarotCard ritualCard(int ritualId) {
  final bridge = OraclyTarotBridge.byRitualId(ritualId);
  if (bridge == null) {
    throw StateError('invalid ritual id $ritualId');
  }
  return TarotCard(
    id: ritualId,
    name: bridge.name.en,
    image: bridge.visualAsset,
    arcana: ritualId <= 21 ? TarotArcana.major : TarotArcana.minor,
    suit: TarotSuit.none,
    number: bridge.number,
    summary: '',
    meaning: '',
    reversedMeaning: '',
    keywords: const [],
  );
}

ReadingSession sessionFromEvidence(Map<String, dynamic> scenario) {
  final input = Map<String, dynamic>.from(scenario['input'] as Map);
  final cards = (input['cards'] as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  return ReadingSession(
    id: input['sessionId'] as String,
    deckId: 'classic',
    spread: spreadTypeNamed(input['spreadType'] as String),
    intention: TarotIntention(
      text: (input['questionRaw'] as String?) ?? '',
      topic: input['intentionTopic'] as String?,
    ),
    shuffleSeed: 1,
    startedAt: DateTime.utc(2026, 9, 1, 12),
    drawnCards: [
      for (final c in cards)
        TarotDrawnCard(
          card: ritualCard(c['ritualCardId'] as int),
          positionIndex: c['positionIndex'] as int,
          isReversed: c['isReversed'] as bool,
          positionKey: c['positionKey'] as String?,
        ),
    ],
  );
}

NarrativeTarotShadowResult evaluateScenario(Map<String, dynamic> scenario) {
  final input = Map<String, dynamic>.from(scenario['input'] as Map);
  return NarrativeTarotClassicalShadow.evaluate(
    session: sessionFromEvidence(scenario),
    readingId: input['readingId'] as String,
    languageCode: input['languageCode'] as String,
  );
}

Map<String, Object?> freezeShadowRecord({
  required Map<String, dynamic> scenario,
  required NarrativeTarotShadowResult result,
}) {
  final input = Map<String, dynamic>.from(scenario['input'] as Map);
  final expected = Map<String, dynamic>.from(scenario['expected'] as Map);
  final req = result.finalNarrativeRequest!;
  return <String, Object?>{
    'scenarioId': scenario['id'],
    'spreadType': input['spreadType'],
    'languageCode': input['languageCode'],
    'narrativeSpreadId': req.spread.spreadId,
    'questionKind': (expected['question'] as Map)['kind'],
    'hasRealQuestion': req.question.hasRealQuestion,
    'cardCount': req.cards.length,
    'ritualCardIds': [for (final c in req.cards) c.ritualCardId],
    'canonicalCardIds': [for (final c in req.cards) c.canonicalCardId],
    'reversed': [for (final c in req.cards) c.isReversed],
    'positionIndices': [for (final c in req.cards) c.positionIndex],
    'positionKeys': [for (final c in req.cards) c.positionKey],
    'relationshipCount': req.relationships.length,
    'narrativeCacheKey': result.narrativeCacheKey,
    'status': result.status.name,
  };
}

ReadingSession relationshipSingleSession() {
  return ReadingSession(
    id: 'sess_hist_6e',
    deckId: 'classic',
    spread: TarotSpreadType.single,
    intention: const TarotIntention(
      text: 'Should I stay in this relationship?',
      topic: 'love',
    ),
    shuffleSeed: 1,
    startedAt: DateTime.utc(2026, 9, 1, 12),
    drawnCards: [
      TarotDrawnCard(
        card: ritualCard(0),
        positionIndex: 0,
        isReversed: false,
        positionKey: 'sign',
      ),
    ],
  );
}
