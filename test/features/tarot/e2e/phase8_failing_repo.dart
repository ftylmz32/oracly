/// Phase 8 — Counting repo + draw/settle fault injection (test-only).
library;

import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/repositories/tarot_reading_repository.dart';

/// Deterministic save faults for Phase 8.3 draw transaction proof.
enum Phase8SaveFault {
  none,
  failBeforeWrite,
  writeThenThrow,
}

/// Fail/delay next [saveSession] for draw/settle fault injection.
class Phase8FailingRepo implements TarotReadingRepository {
  Phase8FailingRepo(this._inner);

  final TarotReadingRepository _inner;

  /// Legacy: next N saves throw before write (fail-before-write).
  int failNextSaves = 0;

  /// Queue of one-shot faults (consumed in order on each save).
  final List<Phase8SaveFault> faultQueue = <Phase8SaveFault>[];

  Duration? delaySaves;
  int saveCount = 0;
  int loadActiveCount = 0;
  bool failNextLoadActive = false;

  Phase8SaveFault _nextFault() {
    if (faultQueue.isNotEmpty) return faultQueue.removeAt(0);
    if (failNextSaves > 0) {
      failNextSaves--;
      return Phase8SaveFault.failBeforeWrite;
    }
    return Phase8SaveFault.none;
  }

  @override
  Future<void> saveSession(ReadingSession session) async {
    if (delaySaves != null) await Future<void>.delayed(delaySaves!);
    final fault = _nextFault();
    switch (fault) {
      case Phase8SaveFault.none:
        saveCount++;
        await _inner.saveSession(session);
        return;
      case Phase8SaveFault.failBeforeWrite:
        throw StateError('persist_failed_before_write');
      case Phase8SaveFault.writeThenThrow:
        saveCount++;
        await _inner.saveSession(session);
        throw StateError('persist_failed_after_write');
    }
  }

  @override
  Future<void> clearActiveSession() => _inner.clearActiveSession();

  @override
  Future<void> deleteSession(String id) => _inner.deleteSession(id);

  @override
  Future<ReadingSession?> loadActiveSession() async {
    loadActiveCount++;
    if (failNextLoadActive) {
      failNextLoadActive = false;
      throw StateError('load_active_failed');
    }
    return _inner.loadActiveSession();
  }

  @override
  Future<List<ReadingSession>> loadAllSessions() => _inner.loadAllSessions();

  @override
  Future<List<ReadingSession>> loadCompletedSessions() =>
      _inner.loadCompletedSessions();

  @override
  Future<ReadingSession?> loadSession(String id) => _inner.loadSession(id);
}
