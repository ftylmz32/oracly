/// Phase 6F — shared offline helpers for live Narrative routing tests.
/// REAL PROVIDER CALLS = 0.
library;

import 'dart:convert';
import 'dart:io';

import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/oracly_narrative_tarot_ai_service.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/interpretation/cache/interpretation_cache.dart';
import 'package:oracly_new/features/tarot/interpretation/models/interpretation_result.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_snapshot_loader.dart';

import '../narrative_shadow/narrative_shadow_test_support.dart';

const solResultsPath =
    'test/fixtures/tarot_narrative_provider_shadow_results_6e8_sol_v2.json';

/// Read-only — the 6E.8 fixture is frozen evidence, never rewritten here.
Map<String, dynamic> loadSolResults() =>
    jsonDecode(File(solResultsPath).readAsStringSync()) as Map<String, dynamic>;

List<Map<String, dynamic>> solCalls() => (loadSolResults()['calls'] as List)
    .map((e) => Map<String, dynamic>.from(e as Map))
    .toList();

TarotHistoricalSnapshotLoadResult emptyHistoryLoad() =>
    TarotHistoricalSnapshotLoadResult(
      snapshot: TarotHistoricalSnapshot(tarotReadings: const []),
      privacyBlocked: false,
    );

TarotHistoricalSnapshotLoadResult privacyBlockedLoad({
  required List<TarotHistoricalReadingRecord> readings,
}) =>
    TarotHistoricalSnapshotLoadResult(
      snapshot: TarotHistoricalSnapshot(tarotReadings: readings),
      privacyBlocked: true,
    );

/// Minimal upright single-card session matching corpus `single_open_fool_en`.
ReadingSession singleFoolSession({String id = 'sess_6f_single'}) =>
    ReadingSession(
      id: id,
      deckId: 'classic',
      spread: TarotSpreadType.single,
      intention: const TarotIntention(text: '', topic: null),
      shuffleSeed: 1,
      startedAt: DateTime.utc(2026, 9, 24, 12),
      drawnCards: [
        TarotDrawnCard(
          card: ritualCard(0),
          positionIndex: 0,
          isReversed: false,
          positionKey: 'sign',
        ),
      ],
    );

/// Narrative provider double — counts calls, replays scripted outcomes.
class ScriptedNarrativeAi implements OraclyNarrativeTarotAiService {
  ScriptedNarrativeAi(this._outcomes);

  final List<AiOutcome<Map<String, dynamic>>> _outcomes;
  final payloads = <Map<String, dynamic>>[];
  final fingerprints = <String>[];

  int get callCount => payloads.length;

  @override
  Future<AiOutcome<Map<String, dynamic>>> generateNarrativeTarotReading({
    required Map<String, dynamic> payload,
    required String fingerprint,
  }) async {
    payloads.add(payload);
    fingerprints.add(fingerprint);
    final index = payloads.length - 1;
    return _outcomes[index < _outcomes.length ? index : _outcomes.length - 1];
  }
}

/// In-memory cache that records every write — billing boundary evidence.
class CountingInterpretationCache implements InterpretationCache {
  final _store = <String, InterpretationResult>{};
  final writes = <String>[];
  int reads = 0;

  @override
  Future<InterpretationResult?> get(String cacheKey) async {
    reads++;
    return _store[cacheKey];
  }

  @override
  Future<void> set(String cacheKey, InterpretationResult result) async {
    writes.add(cacheKey);
    _store[cacheKey] = result;
  }

  @override
  Future<void> invalidate(String cacheKey) async => _store.remove(cacheKey);

  @override
  Future<void> invalidateSession(String sessionId) async =>
      _store.removeWhere((k, _) => k.contains(sessionId));
}
