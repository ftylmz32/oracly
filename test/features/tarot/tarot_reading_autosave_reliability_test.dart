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
import 'package:oracly_new/core/domain/models/achievement.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/domain/models/user_profile.dart';
import 'package:oracly_new/core/domain/repositories/history_repository.dart';
import 'package:oracly_new/core/domain/repositories/user_repository.dart';
import 'package:oracly_new/core/reading_version/models/reading_version_group.dart';
import 'package:oracly_new/core/reading_version/models/reading_version_kind.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_payload.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_service.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_store.dart';
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

/// Fails the ledger write itself on the first N calls, then delegates —
/// simulates history having already saved successfully while the SEPARATE
/// reading-count contribution fails, so a retry must converge on exactly
/// one contribution without duplicating history (which is already
/// idempotent by id on its own).
class _FlakyUserRepository implements UserRepository {
  _FlakyUserRepository(this._real, {required this.failFirstNCalls});

  final UserRepository _real;
  int failFirstNCalls;
  int recordCalls = 0;

  @override
  Future<bool> recordReadingCompletion(String readingId) async {
    recordCalls++;
    if (recordCalls <= failFirstNCalls) {
      throw StateError('simulated reading-count ledger write failure');
    }
    return _real.recordReadingCompletion(readingId);
  }

  @override
  Future<UserProfileModel> getProfile() => _real.getProfile();

  @override
  Future<void> saveProfile(UserProfileModel profile) =>
      _real.saveProfile(profile);

  @override
  Future<List<AchievementModel>> getAchievements() => _real.getAchievements();

  @override
  Future<void> unlockAchievement(String key) => _real.unlockAchievement(key);

  @override
  Future<void> incrementStreak() => _real.incrementStreak();
}

/// Fails the version-seed write itself on the first N calls, then
/// delegates — simulates history+count having already durably succeeded
/// while the SEPARATE version-seed write fails, exactly the P0 commit-point
/// scenario: the whole attempt must be reported as NOT complete even
/// though part of it already durably succeeded.
class _FlakyVersionStore extends ReadingVersionStore {
  _FlakyVersionStore(super.storage, {required this.failFirstNCalls});

  int failFirstNCalls;
  int saveCalls = 0;

  @override
  Future<void> save(ReadingVersionGroup group) async {
    saveCalls++;
    if (saveCalls <= failFirstNCalls) {
      throw StateError('simulated version-seed write failure');
    }
    await super.save(group);
  }
}

/// Mirrors the FULL commit-point shape of `_ReadingScreenState
/// ._persistToJournalBody` after the P0 integrity fix: history + the
/// exactly-once reading count (inside saveFromSession) and version
/// seeding are the durable CORE, both required before reporting success.
/// Analytics is modeled as a separate step that can throw without ever
/// flipping the reported outcome — exactly like the real method's
/// try/catch around `logReadingCompleted`.
Future<bool> _commitLikeReadingScreen({
  required ReadingService readingService,
  required ReadingVersionService versionService,
  required ReadingSession session,
  void Function()? onAnalytics,
}) async {
  try {
    final saved = await readingService.saveFromSession(
      session: session,
      aiSummary: 'Kısa ve sakin bir içgörü.',
    );
    if (saved != null) {
      await versionService.seedOriginal(
        rootId: saved.id,
        kind: ReadingVersionKind.tarot,
        data: ReadingVersionPayload.tarot(saved.aiSummary),
      );
    }
  } catch (_) {
    return false;
  }
  // Best-effort only from here — must never affect the outcome above.
  try {
    onAnalytics?.call();
  } catch (_) {}
  return true;
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

  group('P0: reading count idempotency (recordReadingCompletion)', () {
    test(
        'same stable session saved 3x sequentially -> history has exactly '
        'one entry, totalReadings advances by exactly one', () async {
      final service = ReadingService(realHistory, users);
      final session = _session();

      await service.saveFromSession(session: session, aiSummary: 'a');
      await service.saveFromSession(session: session, aiSummary: 'b');
      await service.saveFromSession(session: session, aiSummary: 'c');

      expect(await realHistory.getReadings(), hasLength(1));
      final profile = await users.getProfile();
      expect(profile.totalReadings, 1);
    });

    test(
        'two concurrent saves for the SAME session contribute to '
        'totalReadings exactly once', () async {
      final service = ReadingService(realHistory, users);
      final session = _session();

      await Future.wait([
        service.saveFromSession(session: session, aiSummary: 'a'),
        service.saveFromSession(session: session, aiSummary: 'b'),
      ]);

      expect(await realHistory.getReadings(), hasLength(1));
      final profile = await users.getProfile();
      expect(profile.totalReadings, 1);
    });

    test(
        'a process restart (fresh repository instances over the SAME '
        'durable storage) replaying the same session still contributes '
        'only once', () async {
      final serviceA = ReadingService(realHistory, users);
      final session = _session();
      await serviceA.saveFromSession(session: session, aiSummary: 'a');

      // Brand-new repository/service instances, same underlying durable
      // storage — the only way a real process restart can differ from
      // continuing in-process.
      final restartedHistory = MockHistoryRepository(storage);
      final restartedUsers = MockUserRepository(storage);
      final serviceB = ReadingService(restartedHistory, restartedUsers);
      await serviceB.saveFromSession(session: session, aiSummary: 'a-again');

      expect(await restartedHistory.getReadings(), hasLength(1));
      final profile = await restartedUsers.getProfile();
      expect(profile.totalReadings, 1);
    });

    test('two distinct sessions each contribute their own +1 (total 2)',
        () async {
      final service = ReadingService(realHistory, users);
      await service.saveFromSession(
        session: _session(id: 'distinct-1'),
        aiSummary: 'a',
      );
      await service.saveFromSession(
        session: _session(id: 'distinct-2'),
        aiSummary: 'b',
      );

      final profile = await users.getProfile();
      expect(profile.totalReadings, 2);
    });

    test(
        'a legacy totalReadings value (from before this ledger existed) is '
        'preserved as a floor — never reset or decreased', () async {
      // Simulates a user who already had 15 readings recorded under the
      // old unconditional-increment mechanism, before recordReadingCompletion
      // ever ran for this install.
      await storage.setInt('profile_readings', 15);
      final service = ReadingService(realHistory, users);

      final before = await users.getProfile();
      expect(before.totalReadings, 15);

      await service.saveFromSession(
        session: _session(id: 'post-legacy-1'),
        aiSummary: 'a',
      );
      final after = await users.getProfile();
      expect(after.totalReadings, 16);

      // Re-saving the SAME session must not move the floor backward or
      // forward again.
      await service.saveFromSession(
        session: _session(id: 'post-legacy-1'),
        aiSummary: 'a-again',
      );
      final again = await users.getProfile();
      expect(again.totalReadings, 16);
    });

    test(
        'history-level partial failure: the count is never touched until '
        'history genuinely succeeds, and retry converges to exactly one',
        () async {
      final flakyHistory = _FlakyHistoryRepository(
        realHistory,
        failFirstNCalls: 1,
      );
      final service = ReadingService(flakyHistory, users);
      final session = _session();

      final firstAttempt = await _persistLikeReadingScreen(service, session);
      expect(firstAttempt, isFalse);
      expect(
        (await users.getProfile()).totalReadings,
        0,
        reason: 'history never saved, so the count must not have moved',
      );

      final retry = await _persistLikeReadingScreen(service, session);
      expect(retry, isTrue);
      expect((await users.getProfile()).totalReadings, 1);

      final again = await _persistLikeReadingScreen(service, session);
      expect(again, isTrue);
      expect(
        (await users.getProfile()).totalReadings,
        1,
        reason: 'idempotent re-save must not add a second contribution',
      );
      expect(await realHistory.getReadings(), hasLength(1));
    });

    test(
        'ledger-level partial failure: history already succeeded but the '
        'count write itself fails once — retry converges to exactly one '
        'contribution, history is never duplicated', () async {
      final flakyUsers = _FlakyUserRepository(users, failFirstNCalls: 1);
      final service = ReadingService(realHistory, flakyUsers);
      final session = _session();

      final firstAttempt = await _persistLikeReadingScreen(service, session);
      expect(
        firstAttempt,
        isFalse,
        reason: 'the ledger write itself threw on this attempt',
      );
      // History already committed on this same attempt, before the ledger
      // write failed — this is exactly the partial-failure window.
      expect(await realHistory.getReadings(), hasLength(1));
      expect((await users.getProfile()).totalReadings, 0);

      final retry = await _persistLikeReadingScreen(service, session);
      expect(retry, isTrue);

      expect(await realHistory.getReadings(), hasLength(1));
      expect((await users.getProfile()).totalReadings, 1);
    });

    test(
        'achievement boundaries cannot be inflated by retries of the same '
        'session', () async {
      final service = ReadingService(realHistory, users);
      final session = _session();

      await service.saveFromSession(session: session, aiSummary: 'a');
      await service.saveFromSession(session: session, aiSummary: 'a again');
      await service.saveFromSession(
        session: session,
        aiSummary: 'a again again',
      );

      final profile = await users.getProfile();
      expect(profile.totalReadings, 1);
      expect(profile.unlockedAchievementKeys, contains('first_reading'));
      expect(profile.unlockedAchievementKeys, isNot(contains('cards_100')));
    });
  });

  group('P0: Tarot journal commit point (history+count+version = durable '
      'core; analytics = best-effort)', () {
    test(
        'production-facing: history, count, and version seed all succeed '
        'together -> commit reports complete exactly once', () async {
      final service = ReadingService(realHistory, users);
      final versionService = ReadingVersionService(
        ReadingVersionStore(storage),
      );
      final session = _session();
      var analyticsCalls = 0;

      final completed = await _commitLikeReadingScreen(
        readingService: service,
        versionService: versionService,
        session: session,
        onAnalytics: () => analyticsCalls++,
      );

      expect(completed, isTrue);
      expect(await realHistory.getReadings(), hasLength(1));
      expect((await users.getProfile()).totalReadings, 1);
      expect(versionService.groupFor(session.id), isNotNull);
      expect(analyticsCalls, 1);
    });

    test(
        'version-seed failure: history+count already durably saved, but '
        'the commit is reported NOT complete — retry converges without '
        'duplicating history, count, or the version seed', () async {
      final flakyStore = _FlakyVersionStore(storage, failFirstNCalls: 1);
      final versionService = ReadingVersionService(flakyStore);
      final service = ReadingService(realHistory, users);
      final session = _session();

      final firstAttempt = await _commitLikeReadingScreen(
        readingService: service,
        versionService: versionService,
        session: session,
      );
      expect(firstAttempt, isFalse);
      // The durable core that DID succeed on this attempt must stand —
      // only the version seed failed.
      expect(await realHistory.getReadings(), hasLength(1));
      expect((await users.getProfile()).totalReadings, 1);
      expect(versionService.groupFor(session.id), isNull);

      final retry = await _commitLikeReadingScreen(
        readingService: service,
        versionService: versionService,
        session: session,
      );
      expect(retry, isTrue);
      expect(await realHistory.getReadings(), hasLength(1));
      expect(
        (await users.getProfile()).totalReadings,
        1,
        reason: 're-saving the same session must not add a second count',
      );
      expect(versionService.groupFor(session.id)!.entries, hasLength(1));

      // A third call (idempotent re-save) must not duplicate anything
      // either, including the already-seeded version.
      final again = await _commitLikeReadingScreen(
        readingService: service,
        versionService: versionService,
        session: session,
      );
      expect(again, isTrue);
      expect(await realHistory.getReadings(), hasLength(1));
      expect((await users.getProfile()).totalReadings, 1);
      expect(versionService.groupFor(session.id)!.entries, hasLength(1));
    });

    test(
        'reading_screen.dart sets the journal gate completed ONLY AFTER '
        'both the save and the version seed, and analytics/invalidation '
        'are wrapped so they can never flip that outcome '
        '(regression lock against reintroducing the P0 contradictory-state '
        'bug)', () {
      final source = File(
        'lib/features/tarot/presentation/screens/reading_screen.dart',
      ).readAsStringSync();

      final method = source.substring(
        source.indexOf('Future<void> _persistToJournalBody('),
        source.indexOf('void _showJournalPersistFailedFeedback('),
      );

      final seedIndex = method.indexOf('.seedOriginal(');
      final completedIndex = method.indexOf('_journalGate.completed = true;');
      expect(seedIndex, greaterThan(-1));
      expect(completedIndex, greaterThan(-1));
      expect(
        completedIndex,
        greaterThan(seedIndex),
        reason: 'the gate must never report complete before the version '
            'seed (part of the durable core) has actually succeeded',
      );

      final analyticsIndex = method.indexOf('logReadingCompleted(');
      expect(analyticsIndex, greaterThan(completedIndex),
          reason: 'analytics must run only after the durable commit point, '
              'never gate it');
      // Analytics failing must be swallowed locally, not merged into the
      // same catch that flips _journalPersistFailed.
      final analyticsRegion = method.substring(analyticsIndex);
      expect(analyticsRegion, contains('} catch (e) {'));
      expect(
        analyticsRegion.indexOf('_journalPersistFailed = true'),
        -1,
        reason: 'a best-effort analytics failure must never re-arm the '
            'save-failed banner',
      );
    });
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
