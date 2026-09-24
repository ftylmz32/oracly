/// Phase 6F — a privacy-blocked snapshot can never reach the wire: no memory,
/// no recurrence, no owner/session/reading identifiers.
/// REAL PROVIDER CALLS = 0.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_snapshot_loader.dart';
import 'package:oracly_new/features/tarot/narrative/live/narrative_tarot_live_request_factory.dart';

import '../narrative_shadow/narrative_shadow_test_support.dart';
import 'phase6f_live_support.dart';

const _owner = 'owner_secret_6f';
const _sessionId = 'session_secret_6f';
const _priorReadingId = 'reading_secret_6f_prior';
const _priorSessionId = 'session_secret_6f_prior';
const _intention = 'Gizli önceki niyet metni';

final _now = DateTime.utc(2026, 9, 24, 19);

/// Identifiers that must never be model-visible in any routing mode.
const _secrets = <String>[
  _owner,
  _sessionId,
  _priorReadingId,
  _priorSessionId,
];

const _leakKeys = <String>[
  'sessionId',
  'readingId',
  'ownerId',
  'evidenceId',
  'sourceId',
  'supportingReadingIds',
  'rel_',
  'rec_card_',
  'rec_theme_',
];

List<TarotHistoricalReadingRecord> _priorReadings() => [
      TarotHistoricalReadingRecord(
        readingId: _priorReadingId,
        sessionId: _priorSessionId,
        ownerId: _owner,
        occurredAt: _now.subtract(const Duration(days: 10)),
        spreadId: 'classical.single',
        intentionSummary: _intention,
        cards: const [
          TarotHistoricalCardOccurrence(
            canonicalCardId: 'major_00',
            isReversed: false,
            positionKey: 'sign',
            positionIndex: 0,
          ),
        ],
      ),
    ];

ReadingSession _session() => ReadingSession(
      id: _sessionId,
      deckId: 'classic',
      userId: _owner,
      spread: TarotSpreadType.single,
      intention: const TarotIntention(text: '', topic: null),
      shuffleSeed: 1,
      startedAt: _now,
      drawnCards: [
        TarotDrawnCard(
          card: ritualCard(0),
          positionIndex: 0,
          isReversed: false,
          positionKey: 'sign',
        ),
      ],
    );

NarrativeTarotLiveBuiltRequest _build({required bool privacyBlocked}) =>
    NarrativeTarotLiveRequestFactory.build(
      session: _session(),
      languageCode: 'en',
      historyLoad: privacyBlocked
          ? privacyBlockedLoad(readings: _priorReadings())
          : TarotHistoricalSnapshotLoadResult(
              snapshot: TarotHistoricalSnapshot(
                tarotReadings: _priorReadings(),
              ),
              privacyBlocked: false,
            ),
      now: _now,
    );

void main() {
  test('privacyBlocked drops memory and recurrence evidence', () {
    final request = _build(privacyBlocked: true).request;
    expect(request.memory.included, isFalse);
    expect(request.memory.omitReason, 'privacy');
    expect(request.memory.entries, isEmpty);
    expect(request.memory.priorReadingCount, 0);
    expect(request.memory.recentCardNames, isEmpty);
    expect(request.memory.recurringThemeLabels, isEmpty);
    expect(request.recurringCards, isEmpty);
    expect(request.recurringThemes, isEmpty);
  });

  test('the same snapshot does produce recurrence when not blocked', () {
    final request = _build(privacyBlocked: false).request;
    expect(
      request.recurringCards,
      isNotEmpty,
      reason: 'contrast proves privacy is what suppressed the evidence',
    );
    expect(request.memory.omitReason, isNot('privacy'));
  });

  for (final blocked in const [true, false]) {
    test('wire payload leaks no identifiers (privacyBlocked: $blocked)', () {
      final wire = jsonEncode(_build(privacyBlocked: blocked).wirePayload);
      for (final secret in _secrets) {
        expect(wire, isNot(contains(secret)), reason: secret);
      }
      for (final key in _leakKeys) {
        expect(wire, isNot(contains(key)), reason: key);
      }
      expect(RegExp(r'\bmem_').hasMatch(wire), isFalse);
      if (blocked) expect(wire, isNot(contains(_intention)));
    });
  }

  test('privacy-blocked memory block stays structurally empty on the wire', () {
    final narrative = Map<String, Object?>.from(
      _build(privacyBlocked: true).wirePayload['narrative']! as Map,
    );
    final memory = Map<String, Object?>.from(narrative['memory']! as Map);
    expect(memory['included'], isFalse);
    expect(memory['entries'], isEmpty);
    expect(memory['priorReadingCount'], 0);
    expect(narrative['recurringCards'], isEmpty);
    expect(narrative['recurringThemes'], isEmpty);
  });
}
