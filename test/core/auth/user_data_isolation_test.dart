/// Two synthetic accounts — local journal, profile, gems, memory stay isolated.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_gateway.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_service.dart';
import 'package:oracly_new/core/auth/firebase/firebase_auth_user.dart';
import 'package:oracly_new/core/auth/firebase/firebase_id_token_manager.dart';
import 'package:oracly_new/core/auth/session_manager.dart';
import 'package:oracly_new/core/auth/token_manager.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_premium_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/premium_plan.dart';
import 'package:oracly_new/core/domain/models/user_profile.dart';
import 'package:oracly_new/core/intelligence/data/personal_memory_store.dart';
import 'package:oracly_new/core/intelligence/domain/models/personal_memory_summary.dart';
import 'package:oracly_new/core/intelligence/services/personal_memory_relevance.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/companion/services/companion_thread_memory.dart';
import 'package:oracly_new/features/discovery_journal/services/discovery_journal_aggregator.dart';
import 'package:oracly_new/features/favorite_moments/data/local_favorite_moments_repository.dart';
import 'package:oracly_new/features/favorite_moments/models/favorite_moment.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_sources.dart';
import 'package:oracly_new/features/personal_discovery/services/discovery_or_context.dart';
import 'package:oracly_new/features/personal_discovery/services/personal_discovery_profile_builder.dart';
import 'package:oracly_new/features/tarot/data/datasources/tarot_local_datasource.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/personal_discovery/pde_test_fixtures.dart';

const _idToken = 'eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.e30.sig';
const _userA = 'synthetic-oracly-user-a';
const _userB = 'synthetic-oracly-user-b';
const _ghost = 'ISOLATIONMARKER42';
const _orQuestion = 'Karar vermekte zorlanıyorum; keşiflerimde ne görüyordun?';

/// Throws when [remove] is called for any key in [failingKeys], then
/// behaves normally for everything else — proves an account switch that
/// hits one unrelated profile-key removal failure still reaches and
/// clears the reading-count ledger/baseline for the next owner.
class _KeyFailingStorage extends LocalStorage {
  _KeyFailingStorage(super.prefs, {required this.failingKeys});

  final Set<String> failingKeys;

  @override
  Future<bool> remove(String key) async {
    if (failingKeys.contains(key)) {
      throw StateError('simulated remove failure for $key');
    }
    return super.remove(key);
  }
}

/// Counts calls to [remove] for specific keys, and adds a small delay so
/// two concurrent transitions have a real window to (incorrectly) overlap
/// if single-flight/serialization isn't actually working.
class _CountingDelayStorage extends LocalStorage {
  _CountingDelayStorage(super.prefs);

  final Map<String, int> removeCallCounts = {};

  @override
  Future<bool> remove(String key) async {
    removeCallCounts[key] = (removeCallCounts[key] ?? 0) + 1;
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return super.remove(key);
  }
}

/// Holds the first wipe-key [remove] until [release] completes — lets a
/// newer Firebase identity event enter `_sessionFromUser` while an older
/// isolation is still mid-wipe.
class _HoldWipeStorage extends LocalStorage {
  _HoldWipeStorage(super.prefs);

  Completer<void>? hold;
  final wipeStarted = Completer<void>();
  int wipeRemoveCalls = 0;

  @override
  Future<bool> remove(String key) async {
    // The reading ledger is always part of UserLocalDataWipe — first hit
    // is a reliable "wipe actually started" signal.
    if (key == MockUserRepository.readingLedgerIdsKey) {
      wipeRemoveCalls++;
      if (!wipeStarted.isCompleted) wipeStarted.complete();
      final gate = hold;
      if (gate != null) await gate.future;
    }
    return super.remove(key);
  }
}

class _SwitchGateway implements FirebaseAuthGateway {
  final _controller = StreamController<FirebaseAuthUserSnapshot?>.broadcast();
  FirebaseAuthUserSnapshot? _user;

  void signInAs(String uid) {
    _user = FirebaseAuthUserSnapshot(uid: uid, isAnonymous: true);
    _controller.add(_user);
  }

  @override
  bool get isInitialized => true;

  @override
  FirebaseAuthUserSnapshot? get currentUser => _user;

  @override
  Stream<FirebaseAuthUserSnapshot?> authStateChanges() => _controller.stream;

  @override
  Future<String?> currentIdToken({bool forceRefresh = false}) async =>
      _user == null ? null : _idToken;

  @override
  Future<FirebaseAuthUserSnapshot> signInAnonymously() async {
    _user ??= const FirebaseAuthUserSnapshot(uid: _userA, isAnonymous: true);
    _controller.add(_user);
    return _user!;
  }

  @override
  Future<FirebaseAuthUserSnapshot> signInWithEmail({
    required String email,
    required String password,
  }) async =>
      signInAnonymously();

  @override
  Future<FirebaseAuthUserSnapshot> signInWithGoogle({
    required String idToken,
    String? accessToken,
  }) async =>
      signInAnonymously();

  @override
  Future<FirebaseAuthUserSnapshot> signInWithApple({required String idToken}) async =>
      signInAnonymously();

  @override
  Future<void> signOut() async {
    _user = null;
    _controller.add(null);
  }

  @override
  Future<void> deleteCurrentUser() async {
    if (_user == null) {
      throw AuthGatewayException('no-current-user', code: 'no-current-user');
    }
    _user = null;
    _controller.add(null);
  }

  @override
  Future<void> reauthenticateWithGoogle({
    required String idToken,
    String? accessToken,
  }) async {}

  @override
  Future<void> reauthenticateWithGoogleProvider() async {}

  @override
  Future<void> reauthenticateWithApple({required String idToken}) async {}

  @override
  Future<void> reauthenticateWithAppleProvider() async {}

  @override
  Future<void> reauthenticateWithEmail({
    required String email,
    required String password,
  }) async {}
}

Future<void> _seedUserA(LocalStorage storage) async {
  final now = DateTime(2026, 8, 20);
  await MockHistoryRepository(storage).saveReading(
    pdeTarot('iso-r1', '$_ghost Karar vermek zor.', at: now),
  );
  await CoffeeReadingStore(storage).save(
    pdeCoffee('iso-c1', '$_ghost Karar verip ilerlemek.', at: now),
  );
  await MockUserRepository(storage).saveProfile(
    const UserProfileModel(name: 'Synthetic Alice', isPremium: true),
  );
  await MockPremiumRepository(storage).activatePlan(PremiumPlanKind.monthly);
  await GemWalletStore(storage).cacheServerBalance(77);
  await LocalFavoriteMomentsRepository(storage).save(
    FavoriteMoment(
      id: 'fav-a',
      source: FavoriteMomentSource.tarot,
      sourceRef: 'iso-r1',
      savedAt: now,
      occurredAt: now,
      quote: _ghost,
    ),
  );
  await PersonalMemoryStore(storage).save(
    const PersonalMemorySummary(
      preferredName: 'Alice',
      fingerprint: 'iso-a',
    ),
  );
  await TarotLocalDataSource(storage).upsert(
    ReadingSession(
      id: 'iso-tarot',
      deckId: 'classic',
      spread: TarotSpreadType.single,
      intention: const TarotIntention(text: _ghost),
      shuffleSeed: 1,
      startedAt: now,
      status: ReadingSessionStatus.completed,
      completedAt: now,
      userId: _userA,
      drawnCards: const [],
    ),
  );
}

Future<void> _assertEmptySession(LocalStorage storage) async {
  expect(await MockHistoryRepository(storage).getReadings(), isEmpty);
  expect(CoffeeReadingStore(storage).all(), isEmpty);
  expect((await MockUserRepository(storage).getProfile()).name, isEmpty);
  expect(MockPremiumRepository(storage).isActiveNow, isFalse);
  expect(GemWalletStore(storage).balance(), 0);
  expect(await LocalFavoriteMomentsRepository(storage).getAll(), isEmpty);
  expect(PersonalMemoryStore(storage).load().isEmpty, isTrue);
  expect(await TarotLocalDataSource(storage).fetchAll(), isEmpty);
  expect(
    DiscoveryJournalAggregator.merge(
      readings: await MockHistoryRepository(storage).getReadings(),
      coffee: CoffeeReadingStore(storage).all(),
    ),
    isEmpty,
  );
}

Future<void> _assertUserAPresent(LocalStorage storage) async {
  final profile = PersonalDiscoveryProfileBuilder.from(
    PersonalDiscoverySources(
      readings: await MockHistoryRepository(storage).getReadings(),
      coffee: CoffeeReadingStore(storage).all(),
    ),
  );
  expect((await MockUserRepository(storage).getProfile()).name, 'Synthetic Alice');
  expect(GemWalletStore(storage).balance(), 77);
  expect(MockPremiumRepository(storage).isActiveNow, isTrue);
  expect(DiscoveryOrContext.compact(profile), isNotNull);
  expect(
    PersonalMemoryRelevance.hintForMessage(profile, _orQuestion),
    isNotNull,
  );
  expect(
    jsonEncode(PersonalMemoryStore(storage).load().toJson()),
    contains('Alice'),
  );
}

void main() {
  late LocalStorage storage;
  late InMemorySecureStorage secure;
  late _SwitchGateway gateway;
  late FirebaseAuthService auth;
  late UserLocalDataIsolation isolation;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    secure = InMemorySecureStorage();
    gateway = _SwitchGateway();
    isolation = UserLocalDataIsolation(
      storage,
      secureStorage: secure,
    );
    auth = FirebaseAuthService(
      gateway: gateway,
      tokens: FirebaseIdTokenManager(gateway, fallback: _MemTokens()),
      sessions: InMemorySessionManager(_MemTokens()),
      isolation: isolation,
    );
  });

  tearDown(() => auth.dispose());

  test('user B cannot see user A local journal profile gems premium memory',
      () async {
    gateway.signInAs(_userA);
    await auth.signInAnonymously();
    await _seedUserA(storage);
    await _assertUserAPresent(storage);

    await auth.signOut();
    gateway.signInAs(_userB);
    await auth.signInAnonymously();

    await _assertEmptySession(storage);
    expect(isolation.localOwnerId, _userB);

    final emptyProfile = PersonalDiscoveryProfileBuilder.from(
      PersonalDiscoverySources(
        readings: await MockHistoryRepository(storage).getReadings(),
        coffee: CoffeeReadingStore(storage).all(),
      ),
    );
    final hint = CompanionThreadMemory.merge(
      discovery: DiscoveryOrContext.compactForMessage(emptyProfile, _orQuestion),
      turns: const [],
      current: _orQuestion,
    );
    expect(hint.toLowerCase(), isNot(contains(_ghost.toLowerCase())));

    // FINAL gates
    expect(await MockHistoryRepository(storage).getReadings(), isEmpty,
        reason: 'JOURNAL');
    expect(PersonalMemoryStore(storage).load().isEmpty, isTrue, reason: 'MEMORY');
    expect(GemWalletStore(storage).balance(), 0, reason: 'GEMS');
    expect(isolation.localOwnerId, isNot(_userA), reason: 'ISOLATION');
  });

  test(
      'owner B inherits NEITHER owner A\'s reading-count ledger, legacy '
      'baseline, totalReadings, nor achievements — and owner B\'s own '
      'first reading counts exactly once with no owner-A id leaking in',
      () async {
    gateway.signInAs(_userA);
    await auth.signInAnonymously();

    // Owner A: activate the ledger and record one genuinely new reading —
    // ends with a real, non-empty ledger, a set (non-null) baseline, and
    // totalReadings > 0 (exactly what "migrated ledger state" means).
    final usersA = MockUserRepository(storage);
    final historyA = MockHistoryRepository(storage);
    final now = DateTime(2026, 8, 20);
    await usersA.ensureReadingCompletionMigration(const []);
    await historyA.saveReading(
      pdeTarot('owner-a-r1', '$_ghost owner A reading', at: now),
    );
    await usersA.recordReadingCompletion('owner-a-r1');
    final beforeSwitch = await usersA.getProfile();
    expect(beforeSwitch.totalReadings, 1);
    expect(beforeSwitch.unlockedAchievementKeys, contains('first_reading'));
    expect(
      storage.getStringList(MockUserRepository.readingLedgerIdsKey),
      ['owner-a-r1'],
    );
    expect(storage.getInt(MockUserRepository.legacyBaselineKey), 0);

    // Switch accounts — the same real onSignedIn-driven wipe path the rest
    // of this file already exercises for profile/gems/memory.
    await auth.signOut();
    gateway.signInAs(_userB);
    await auth.signInAnonymously();
    expect(isolation.localOwnerId, _userB);

    // Immediately after the switch: nothing of owner A's reading state
    // survives, and a FRESH MockUserRepository instance over the same
    // storage confirms totalReadings starts at a genuine zero for B, not
    // owner A's baseline.
    expect(
      storage.getStringList(MockUserRepository.readingLedgerIdsKey),
      isNull,
    );
    expect(storage.getInt(MockUserRepository.legacyBaselineKey), isNull);
    expect(storage.getInt('profile_readings'), isNull);
    expect(await MockHistoryRepository(storage).getReadings(), isEmpty);
    final usersB = MockUserRepository(storage);
    final freshProfile = await usersB.getProfile();
    expect(freshProfile.totalReadings, 0);
    expect(freshProfile.unlockedAchievementKeys, isEmpty);

    // Owner B's own first reading — migration must activate fresh for B
    // (no owner-A residue to reconcile against) and contribute exactly
    // one, tagged only under B's own id.
    final historyB = MockHistoryRepository(storage);
    await historyB.saveReading(
      pdeTarot('owner-b-r1', 'owner B reading', at: now),
    );
    await usersB.ensureReadingCompletionMigration(['owner-b-r1']);
    await usersB.recordReadingCompletion('owner-b-r1');

    final afterOwnerBReading = await usersB.getProfile();
    expect(afterOwnerBReading.totalReadings, 1);
    final ledgerAfterB =
        storage.getStringList(MockUserRepository.readingLedgerIdsKey) ??
            const [];
    expect(ledgerAfterB, ['owner-b-r1']);
    expect(ledgerAfterB, isNot(contains('owner-a-r1')));
  });

  Future<void> runLedgerOwnerSwitchFailureScenario({
    required String failingKey,
    required String ownerA,
    required String ownerB,
  }) async {
    final switchEpochBefore = UserLocalDataIsolation.accountSwitchEpoch.value;
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final failingStorage = _KeyFailingStorage(prefs, failingKeys: {failingKey});
    final failingSecure = InMemorySecureStorage();
    final failingIsolation = UserLocalDataIsolation(
      failingStorage,
      secureStorage: failingSecure,
    );
    final switchGateway = _SwitchGateway();
    final switchSessions = InMemorySessionManager(_MemTokens());
    final switchAuth = FirebaseAuthService(
      gateway: switchGateway,
      tokens: _MemTokens(),
      sessions: switchSessions,
      isolation: failingIsolation,
    );

    // Owner A signs in first (no switch needed yet) and builds a real,
    // migrated ledger.
    switchGateway.signInAs(ownerA);
    final firstSignIn = await switchAuth.signInAnonymously();
    expect(firstSignIn.isSuccess, isTrue);
    expect(failingIsolation.localOwnerId, ownerA);
    final usersA = MockUserRepository(failingStorage);
    final historyA = MockHistoryRepository(failingStorage);
    await usersA.ensureReadingCompletionMigration(const []);
    await historyA.saveReading(
      pdeTarot('$ownerA-r1', '$_ghost owner A reading', at: DateTime(2026, 8, 20)),
    );
    await usersA.recordReadingCompletion('$ownerA-r1');
    expect((await usersA.getProfile()).totalReadings, 1);

    // Attempt to switch to owner B through the REAL auth + isolation
    // path — the failing key's own removal throws.
    switchGateway.signInAs(ownerB);
    final switchAttempt = await switchAuth.signInAnonymously();

    expect(
      switchAttempt.isFailure,
      isTrue,
      reason: 'a session for owner B must never be reported successful '
          'while local isolation has not actually completed',
    );
    expect(
      switchSessions.currentSession,
      isNull,
      reason: 'Firebase is now owner B, so a stale owner-A application '
          'session left in place would be Firebase-uid-B + '
          'application-session-uid-A — not a safe state, even though B '
          'itself was correctly never committed. The session must be '
          'cleared, not merely "still A".',
    );
    expect(
      failingIsolation.localOwnerId,
      ownerA,
      reason: 'ownerKey must NOT be re-labelled to B merely because the '
          'wipe attempted on B\'s behalf was incomplete',
    );
    expect(
      failingStorage.peek(failingKey),
      isNotNull,
      reason: 'the deliberately failing key itself may remain',
    );
    expect(await historyA.getReadings(), isEmpty,
        reason: 'independent later cleanup still ran');
    expect(
      UserLocalDataIsolation.accountSwitchEpoch.value,
      switchEpochBefore,
      reason: 'an incomplete switch must not announce a completed one',
    );

    // Make storage healthy and retry.
    final healthyStorage = LocalStorage(prefs);
    final healthyIsolation = UserLocalDataIsolation(
      healthyStorage,
      secureStorage: failingSecure,
    );
    final retryResult = await healthyIsolation.onSignedIn(ownerB);

    expect(retryResult.success, isTrue);
    expect(healthyIsolation.localOwnerId, ownerB);
    expect(healthyStorage.getStringList(failingKey), isNull);
    expect(healthyStorage.getInt(failingKey), isNull);
    final usersB = MockUserRepository(healthyStorage);
    final freshProfile = await usersB.getProfile();
    expect(freshProfile.totalReadings, 0);
    expect(
      healthyStorage.getStringList(MockUserRepository.readingLedgerIdsKey),
      isNot(contains('$ownerA-r1')),
    );
  }

  test(
      'the reading-count LEDGER key\'s own removal failure blocks owner '
      'commit and the successful application session; retry after '
      'storage recovers completes the switch cleanly', () async {
    await runLedgerOwnerSwitchFailureScenario(
      failingKey: MockUserRepository.readingLedgerIdsKey,
      ownerA: 'owner-a-ledger-fail',
      ownerB: 'owner-b-ledger-fail',
    );
  });

  test(
      'the legacy BASELINE key\'s own removal failure blocks owner commit '
      'and the successful application session; retry after storage '
      'recovers completes the switch cleanly', () async {
    await runLedgerOwnerSwitchFailureScenario(
      failingKey: MockUserRepository.legacyBaselineKey,
      ownerA: 'owner-a-baseline-fail',
      ownerB: 'owner-b-baseline-fail',
    );
  });

  test(
      'the auth-state-change listener never leaks an unhandled exception '
      'when isolation fails for the switch it is reacting to', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final failingStorage = _KeyFailingStorage(
      prefs,
      failingKeys: {MockUserRepository.readingLedgerIdsKey},
    );
    final failingIsolation = UserLocalDataIsolation(
      failingStorage,
      secureStorage: InMemorySecureStorage(),
    );
    final leakGateway = _SwitchGateway();
    Object? unhandled;

    await runZonedGuarded(() async {
      final leakAuth = FirebaseAuthService(
        gateway: leakGateway,
        tokens: _MemTokens(),
        sessions: InMemorySessionManager(_MemTokens()),
        isolation: failingIsolation,
      );
      leakGateway.signInAs('owner-a-leak');
      await leakAuth.signInAnonymously();
      await MockUserRepository(failingStorage).ensureReadingCompletionMigration(
        const [],
      );

      // This switch's isolation will fail (the ledger key's own removal
      // throws) — both the explicit call below AND the auth-state-change
      // listener independently reacting to the same gateway event must
      // resolve to an honest ApiFailure, never an unhandled exception.
      leakGateway.signInAs('owner-b-leak');
      await leakAuth.signInAnonymously();
      await Future<void>.delayed(Duration.zero);
      leakAuth.dispose();
    }, (error, stack) => unhandled = error);

    expect(unhandled, isNull);
  });

  test(
      'P0-3: two concurrent onSignedIn calls for the SAME target uid share '
      'ONE in-flight transition — the wipe runs exactly once, both callers '
      'observe the identical outcome', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final countingStorage = _CountingDelayStorage(prefs);
    await countingStorage.setString(
      UserLocalDataIsolation.ownerKey,
      'owner-a-concurrent',
    );
    final isolation = UserLocalDataIsolation(
      countingStorage,
      secureStorage: InMemorySecureStorage(),
    );

    final call1 = isolation.onSignedIn('owner-b-concurrent');
    final call2 = isolation.onSignedIn('owner-b-concurrent');
    final results = await Future.wait([call1, call2]);

    expect(
      identical(call1, call2),
      isTrue,
      reason: 'the second caller must share the exact same in-flight '
          'Future, not start an independent second transition',
    );
    expect(results[0].success, isTrue);
    expect(results[1].success, isTrue);
    expect(
      countingStorage.removeCallCounts[MockUserRepository.readingLedgerIdsKey] ??
          0,
      1,
      reason: 'the ledger removal must have been attempted exactly once '
          'for this ONE logical transition, not once per caller',
    );
    expect(isolation.localOwnerId, 'owner-b-concurrent');
  });

  test(
      'P0-3: two concurrent onSignedIn calls for DIFFERENT target uids '
      'serialize — no overlapping wipes, and the final owner corresponds '
      'to the LAST transition without either wipe running twice',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final countingStorage = _CountingDelayStorage(prefs);
    await countingStorage.setString(
      UserLocalDataIsolation.ownerKey,
      'owner-a-serial',
    );
    final isolation = UserLocalDataIsolation(
      countingStorage,
      secureStorage: InMemorySecureStorage(),
    );

    // Fired back-to-back, neither awaited before the other starts.
    final callB = isolation.onSignedIn('owner-b-serial');
    final callC = isolation.onSignedIn('owner-c-serial');
    final results = await Future.wait([callB, callC]);

    expect(results[0].success, isTrue);
    expect(results[1].success, isTrue);
    expect(
      isolation.localOwnerId,
      'owner-c-serial',
      reason: 'the LAST-enqueued transition (A->B, then B->C once A->B has '
          'fully settled) determines the final owner',
    );
    // Each of the two DISTINCT transitions (A->B, then B->C) removes the
    // ledger key once on its own path (it starts absent, so removal is a
    // safe no-op each time) — exactly two attempts total, never more,
    // which is only possible if they never overlapped.
    expect(
      countingStorage.removeCallCounts[MockUserRepository.readingLedgerIdsKey] ??
          0,
      2,
    );
  });

  test(
      'P0-3: a concurrent refresh for the SAME already-current owner never '
      'triggers a wipe at all', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final countingStorage = _CountingDelayStorage(prefs);
    await countingStorage.setString(
      UserLocalDataIsolation.ownerKey,
      'owner-same',
    );
    final isolation = UserLocalDataIsolation(
      countingStorage,
      secureStorage: InMemorySecureStorage(),
    );

    final call1 = isolation.onSignedIn('owner-same');
    final call2 = isolation.onSignedIn('owner-same');
    final results = await Future.wait([call1, call2]);

    expect(results[0].success, isTrue);
    expect(results[1].success, isTrue);
    expect(
      countingStorage.removeCallCounts[MockUserRepository.readingLedgerIdsKey],
      isNull,
      reason: 'same owner, no switch — no wipe of any kind may run',
    );
  });

  test(
      'P0-3: through the REAL FirebaseAuthService, an explicit sign-in '
      'call and the auth-state-change listener reacting to the SAME '
      'underlying event produce exactly ONE logical A->B wipe — the '
      'ledger removal is attempted once, not once per caller', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final countingStorage = _CountingDelayStorage(prefs);
    final countingIsolation = UserLocalDataIsolation(
      countingStorage,
      secureStorage: InMemorySecureStorage(),
    );
    final realGateway = _SwitchGateway();
    final realAuth = FirebaseAuthService(
      gateway: realGateway,
      tokens: _MemTokens(),
      sessions: InMemorySessionManager(_MemTokens()),
      isolation: countingIsolation,
    );

    realGateway.signInAs('owner-a-real-count');
    await realAuth.signInAnonymously();

    realGateway.signInAs('owner-b-real-count');
    final explicitCall = realAuth.signInAnonymously();
    // Give the auth-state-change listener's own independently-triggered
    // call a chance to actually start before the explicit call settles.
    await Future<void>.delayed(Duration.zero);
    final explicitResult = await explicitCall;
    // Let anything the listener scheduled fully settle too.
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(explicitResult.isSuccess, isTrue);
    expect(countingIsolation.localOwnerId, 'owner-b-real-count');
    expect(
      countingStorage.removeCallCounts[MockUserRepository.readingLedgerIdsKey] ??
          0,
      1,
      reason: 'a single logical A->B transition, regardless of how many '
          'independent callers observed the same underlying auth event',
    );
    realAuth.dispose();
  });

  test(
      'P0-3 A→B→C: releasing a paused B isolation after Firebase is already '
      'C never publishes B — eventual session and owner are C only', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final holdStorage = _HoldWipeStorage(prefs);
    holdStorage.hold = Completer<void>();
    final holdIsolation = UserLocalDataIsolation(
      holdStorage,
      secureStorage: InMemorySecureStorage(),
    );
    final raceGateway = _SwitchGateway();
    final sessions = InMemorySessionManager(_MemTokens());
    final raceAuth = FirebaseAuthService(
      gateway: raceGateway,
      tokens: _MemTokens(),
      sessions: sessions,
      isolation: holdIsolation,
    );

    raceGateway.signInAs('uid-A');
    await raceAuth.signInAnonymously();
    expect(sessions.currentSession?.userId, 'uid-A');

    // Seed a prior owner so B's sign-in must wipe (and hit our hold).
    await holdStorage.setString(UserLocalDataIsolation.ownerKey, 'uid-A');
    await holdStorage.setStringList(
      MockUserRepository.readingLedgerIdsKey,
      const ['seed'],
    );

    raceGateway.signInAs('uid-B');
    final bFuture = raceAuth.signInAnonymously();
    await holdStorage.wipeStarted.future;

    // Firebase is already C while B is still mid-wipe.
    raceGateway.signInAs('uid-C');
    final cFuture = raceAuth.signInAnonymously();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    holdStorage.hold!.complete();
    final bResult = await bFuture;
    final cResult = await cFuture;
    await Future<void>.delayed(const Duration(milliseconds: 40));

    expect(
      bResult.isFailure,
      isTrue,
      reason: 'stale B must never publish after C superseded it',
    );
    expect(cResult.isSuccess, isTrue);
    expect(sessions.currentSession?.userId, 'uid-C');
    expect(holdIsolation.localOwnerId, 'uid-C');
    expect(raceGateway.currentUser?.uid, 'uid-C');
    raceAuth.dispose();
  });

  test(
      'P0-3 A→B→C→B: an old first-B async must not become current merely '
      'because uid later returns to B — generation, not uid equality',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final holdStorage = _HoldWipeStorage(prefs);
    holdStorage.hold = Completer<void>();
    final holdIsolation = UserLocalDataIsolation(
      holdStorage,
      secureStorage: InMemorySecureStorage(),
    );
    final raceGateway = _SwitchGateway();
    final sessions = InMemorySessionManager(_MemTokens());
    final raceAuth = FirebaseAuthService(
      gateway: raceGateway,
      tokens: _MemTokens(),
      sessions: sessions,
      isolation: holdIsolation,
    );

    raceGateway.signInAs('uid-A');
    await raceAuth.signInAnonymously();
    await holdStorage.setString(UserLocalDataIsolation.ownerKey, 'uid-A');
    await holdStorage.setStringList(
      MockUserRepository.readingLedgerIdsKey,
      const ['seed'],
    );

    raceGateway.signInAs('uid-B');
    final firstB = raceAuth.signInAnonymously();
    await holdStorage.wipeStarted.future;

    raceGateway.signInAs('uid-C');
    final cFuture = raceAuth.signInAnonymously();
    await Future<void>.delayed(const Duration(milliseconds: 20));

    holdStorage.hold!.complete();
    final firstBResult = await firstB;
    final cResult = await cFuture;
    expect(firstBResult.isFailure, isTrue);
    expect(cResult.isSuccess, isTrue);
    expect(sessions.currentSession?.userId, 'uid-C');

    // Later return to B — a NEW generation. First-B must stay failed.
    raceGateway.signInAs('uid-B');
    final secondB = await raceAuth.signInAnonymously();
    expect(secondB.isSuccess, isTrue);
    expect(sessions.currentSession?.userId, 'uid-B');
    expect(holdIsolation.localOwnerId, 'uid-B');
    expect(firstBResult.isFailure, isTrue);
    raceAuth.dispose();
  });

  test(
      'P0-3: a stale callback after sign-out must never recreate a session',
      () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final holdStorage = _HoldWipeStorage(prefs);
    holdStorage.hold = Completer<void>();
    final holdIsolation = UserLocalDataIsolation(
      holdStorage,
      secureStorage: InMemorySecureStorage(),
    );
    final raceGateway = _SwitchGateway();
    final sessions = InMemorySessionManager(_MemTokens());
    final raceAuth = FirebaseAuthService(
      gateway: raceGateway,
      tokens: _MemTokens(),
      sessions: sessions,
      isolation: holdIsolation,
    );

    raceGateway.signInAs('uid-A');
    await raceAuth.signInAnonymously();
    await holdStorage.setString(UserLocalDataIsolation.ownerKey, 'uid-A');
    await holdStorage.setStringList(
      MockUserRepository.readingLedgerIdsKey,
      const ['seed'],
    );

    raceGateway.signInAs('uid-B');
    final bFuture = raceAuth.signInAnonymously();
    await holdStorage.wipeStarted.future;

    await raceAuth.signOut();
    expect(sessions.currentSession, isNull);

    holdStorage.hold!.complete();
    final bResult = await bFuture;
    expect(bResult.isFailure, isTrue);
    expect(sessions.currentSession, isNull);
    raceAuth.dispose();
  });

  test('same synthetic user starts empty after logout wipe then login', () async {
    gateway.signInAs(_userA);
    await auth.signInAnonymously();
    await _seedUserA(storage);

    await auth.signOut();
    // R5 — explicit logout wipe (profileSignOut path) clears account data.
    await UserLocalDataWipe.run(storage, secureStorage: secure);
    await storage.remove(UserLocalDataIsolation.ownerKey);

    gateway.signInAs(_userA);
    await auth.signInAnonymously();

    await _assertEmptySession(storage);
    expect(isolation.localOwnerId, _userA);
  });
}

class _MemTokens implements TokenManager {
  String? access;
  String? refresh;

  @override
  Future<String?> getAccessToken({bool forceRefresh = false}) async => access;

  @override
  Future<String?> getRefreshToken() async => refresh;

  @override
  Future<void> saveTokens({
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<bool> hasValidAccessToken() async =>
      access != null && access!.isNotEmpty;

  @override
  Future<void> clearTokens() async {
    access = null;
    refresh = null;
  }
}
