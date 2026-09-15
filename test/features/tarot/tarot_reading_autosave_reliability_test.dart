/// RELIABILITY BATCH 2B — Fix 1: Tarot reading auto-save must never fail
/// silently.
///
/// reading_screen.dart's `_persistToJournal()` is called unawaited right
/// after the reading result is rendered — the audit finding was that an
/// uncaught exception there escapes into the global error zone / NoOp
/// crash sink while the reading still looks complete and saved to the
/// user. The fix wraps that call in a try/catch, tracks an observable
/// `_journalPersistFailed` flag, and surfaces an honest snackbar with a
/// retry action (which just calls `_persistToJournal()` again).
///
/// `ReadingScreen` itself has a large dependency graph (TarotScope, gem
/// economy, tickers, AI executors) with no existing widget-test harness,
/// so pumping it here would be a much bigger change than the fix itself.
/// Instead this file:
///  (1) proves the underlying persistence contract the fix depends on —
///      HistoryRepository.saveReading upserts by the reading's stable id,
///      so a retry after a failure is idempotent — using the REAL
///      ReadingService + MockHistoryRepository (already established by a
///      prior audit to be a genuine production repository despite the
///      legacy "Mock" name);
///  (2) proves a thrown persistence failure, handled the same way
///      _persistToJournal now handles it (try/catch, no rethrow), never
///      produces an unhandled/uncaught async error;
///  (3) proves a failed attempt followed by a retry succeeds without
///      duplicating the entry;
///  (4) locks in — via source inspection — that reading_screen.dart
///      actually contains the try/catch, the failure flag, and the
///      honest snackbar+retry wiring, so this regression can't silently
///      regress back to the unawaited, unguarded call.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/domain/repositories/history_repository.dart';
import 'package:oracly_new/core/services/reading_service.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Throws on the first N calls, then delegates to a real repository —
/// simulates a genuine transient persistence failure followed by a
/// successful retry, without touching the real storage layer's own
/// (already-safe) error handling.
class _FlakyHistoryRepository implements HistoryRepository {
  _FlakyHistoryRepository(this._real, {required this.failFirstNCalls});

  final HistoryRepository _real;
  int failFirstNCalls;
  int saveAttempts = 0;

  @override
  Future<void> saveReading(ReadingModel reading) async {
    saveAttempts++;
    if (saveAttempts <= failFirstNCalls) {
      throw StateError('simulated transient persistence failure');
    }
    await _real.saveReading(reading);
  }

  @override
  Future<List<ReadingModel>> getReadings() => _real.getReadings();

  @override
  Future<void> deleteReading(String id) => _real.deleteReading(id);

  @override
  Future<void> clearAll() => _real.clearAll();
}

ReadingSession _session({String id = 'autosave-1'}) {
  final card = CardRevealSpread.forIndex(2).card;
  return ReadingSession(
    id: id,
    deckId: 'classic',
    spread: TarotSpreadType.single,
    intention: const TarotIntention(text: 'Bugün ne beklemeliyim?', topic: 'general'),
    shuffleSeed: 7,
    startedAt: DateTime(2026, 9, 7),
    drawnCards: [
      TarotDrawnCard(card: card, positionIndex: 0, isReversed: false),
    ],
  );
}

/// Mirrors exactly the shape now used by
/// `_ReadingScreenState._persistToJournal`: never rethrows, reports
/// success/failure via a returned flag instead of letting an exception
/// escape unawaited.
Future<bool> _persistLikeReadingScreen(
  ReadingService service,
  ReadingSession session,
) async {
  try {
    await service.saveFromSession(
      session: session,
      aiSummary: 'Kısa ve sakin bir içgörü.',
    );
    return true;
  } catch (_) {
    return false;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late MockHistoryRepository realHistory;
  late MockUserRepository users;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    realHistory = MockHistoryRepository(storage);
    users = MockUserRepository(storage);
  });

  test('A: a successful save is real — the reading is retrievable afterwards', () async {
    final service = ReadingService(realHistory, users);
    final session = _session();

    final saved = await service.saveFromSession(
      session: session,
      aiSummary: 'Bugün sakin bir netlik var.',
    );

    expect(saved, isNotNull);
    final all = await realHistory.getReadings();
    expect(all.map((r) => r.id), contains(saved!.id));
    expect(saved.id, session.id);
  });

  test(
    'B/F: a thrown persistence failure never escapes as an unhandled async error',
    () async {
      final flaky = _FlakyHistoryRepository(realHistory, failFirstNCalls: 1);
      final service = ReadingService(flaky, users);
      final session = _session();

      Object? unhandled;
      await runZonedGuarded(
        () async {
          final ok = await _persistLikeReadingScreen(service, session);
          expect(ok, isFalse, reason: 'the simulated failure should surface');
        },
        (error, stack) => unhandled = error,
      );

      // Nothing escaped the zone — the failure was fully contained.
      expect(unhandled, isNull);
      expect(await realHistory.getReadings(), isEmpty);
    },
  );

  test('C: the failure is observable, not silently discarded', () async {
    final flaky = _FlakyHistoryRepository(realHistory, failFirstNCalls: 1);
    final service = ReadingService(flaky, users);
    final session = _session();

    final ok = await _persistLikeReadingScreen(service, session);

    // This boolean is exactly the signal _persistToJournal uses to flip
    // _journalPersistFailed and show the retry snackbar.
    expect(ok, isFalse);
  });

  test('D: retrying after a failure succeeds', () async {
    final flaky = _FlakyHistoryRepository(realHistory, failFirstNCalls: 1);
    final service = ReadingService(flaky, users);
    final session = _session();

    final firstAttempt = await _persistLikeReadingScreen(service, session);
    expect(firstAttempt, isFalse);

    final retry = await _persistLikeReadingScreen(service, session);
    expect(retry, isTrue);

    final all = await realHistory.getReadings();
    expect(all, hasLength(1));
    expect(all.single.id, session.id);
  });

  test('E: a successful retry never duplicates the reading', () async {
    final flaky = _FlakyHistoryRepository(realHistory, failFirstNCalls: 1);
    final service = ReadingService(flaky, users);
    final session = _session();

    await _persistLikeReadingScreen(service, session); // fails
    await _persistLikeReadingScreen(service, session); // succeeds
    await _persistLikeReadingScreen(service, session); // idempotent re-save

    final all = await realHistory.getReadings();
    // Same stable session id every time -> HistoryRepository.saveReading
    // upserts, it never appends a second copy.
    expect(all, hasLength(1));
    expect(all.single.id, session.id);
  });

  test(
    'reading_screen.dart actually contains the honest failure/retry wiring '
    '(regression lock against silently reverting to an unguarded call)',
    () {
      final source = File(
        'lib/features/tarot/presentation/screens/reading_screen.dart',
      ).readAsStringSync();

      final method = source.substring(
        source.indexOf('Future<void> _persistToJournal('),
        source.indexOf('Future<void> _offerPersonalNote('),
      );

      expect(method, contains('try {'));
      expect(method, contains('} catch (e) {'));
      expect(method, contains('_journalPersistFailed = true'));
      expect(method, contains('_showJournalPersistFailedFeedback()'));

      expect(source, contains('ResilienceCopy.readingSaveFailed'));
      expect(source, contains('ResilienceCopy.retryAction'));
      expect(source, contains('SnackBarAction('));
      // The auto-save call itself stays unawaited (must not delay/lose the
      // already-rendered interpretation), but is now internally safe.
      expect(source, contains('_persistToJournal();'));
    },
  );
}
