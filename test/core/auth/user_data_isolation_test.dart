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
import 'package:oracly_new/features/gems/models/gem_transaction.dart';
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
  await GemWalletStore(storage).write(
    balance: 77,
    transaction: GemTransaction(
      id: 'tx-a',
      createdAt: now,
      amount: 77,
      reason: 'seed',
      type: GemTransactionType.earned,
    ),
  );
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

  test('same synthetic user keeps local data after logout and login', () async {
    gateway.signInAs(_userA);
    await auth.signInAnonymously();
    await _seedUserA(storage);

    await auth.signOut();
    gateway.signInAs(_userA);
    await auth.signInAnonymously();

    await _assertUserAPresent(storage);
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
