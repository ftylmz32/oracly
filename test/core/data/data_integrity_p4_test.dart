/// P4 data integrity audit tests — includes persistence gate regressions.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_ai_conversation_repository.dart';
import 'package:oracly_new/core/data/repositories/local_astrology_repository.dart';
import 'package:oracly_new/core/data/repositories/local_birth_chart_repository.dart';
import 'package:oracly_new/core/data/repositories/local_dream_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/user_profile.dart';
import 'package:oracly_new/core/intelligence/data/intelligence_index_store.dart';
import 'package:oracly_new/core/intelligence/domain/models/intelligence_facet_counts.dart';
import 'package:oracly_new/core/services/history_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/astrology/data/astrology_preferences_store.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/companion/services/first_reading_or_deepen.dart';
import 'package:oracly_new/features/daily_rewards/services/daily_rewards_service.dart';
import 'package:oracly_new/features/favorite_moments/data/local_favorite_moments_repository.dart';
import 'package:oracly_new/features/favorite_moments/models/favorite_moment.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/gems/services/gem_starter_grant.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/personal_discovery/data/discovery_surface_memory.dart';
import 'package:oracly_new/features/privacy/services/privacy_discovery_clear.dart';
import 'package:oracly_new/features/tarot/data/datasources/tarot_local_datasource.dart';
import 'package:oracly_new/screens/profile/data/profile_photo_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;
  late InMemorySecureStorage secure;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    secure = InMemorySecureStorage();
  });

  test('gem history skips corrupt rows and keeps spend path usable', () async {
    final wallet = GemWalletService(GemWalletStore(storage));
    await wallet.earn(amount: 30, reason: 'seed');
    await storage.setStringList(GemWalletStore.txKey, [
      'not-json',
      '{"id":"","amount":1,"reason":"x","type":"earned","createdAt":"2026-01-01"}',
      ...?storage.getStringList(GemWalletStore.txKey),
    ]);
    expect(wallet.history, isNotEmpty);
    await wallet.spend(amount: 10, reason: 'ok');
    expect(wallet.balance, 20);
  });

  test('starter grant crash-after-earn still completes without double credit',
      () async {
    final wallet = GemWalletService(GemWalletStore(storage));
    await wallet.earn(
      amount: GemEconomy.starterGrant,
      reason: 'partial',
      operationId: GemStarterGrant.operationId,
    );
    expect(wallet.balance, GemEconomy.starterGrant);
    expect(storage.getBool(GemStarterGrant.flagKey), isNot(true));

    final starter = GemStarterGrant(wallet, storage);
    expect(await starter.ensureOnce(), isTrue);
    expect(wallet.balance, GemEconomy.starterGrant);
    expect(storage.getBool(GemStarterGrant.flagKey), isTrue);
    expect(await starter.ensureOnce(), isFalse);
  });

  test('profile name syncs legacy user_name and survives reopen', () async {
    final repo = MockUserRepository(storage);
    await repo.saveProfile(const UserProfileModel(name: 'Fatih', job: 'Eng'));
    expect(storage.getString('profile_name'), 'Fatih');
    expect(storage.getString('user_name'), 'Fatih');

    final reopened = MockUserRepository(
      LocalStorage(await SharedPreferences.getInstance()),
    );
    final profile = await reopened.getProfile();
    expect(profile.name, 'Fatih');
    expect(profile.job, 'Eng');
  });

  test('unknown favorite source is skipped never coerced to tarot', () async {
    final repo = LocalFavoriteMomentsRepository(storage);
    await storage.setStringList(LocalFavoriteMomentsRepository.key, [
      jsonEncode({
        'id': 'bad',
        'source': 'unknown_feature',
        'sourceRef': 'x',
        'savedAt': '2026-01-01T00:00:00.000',
        'occurredAt': '2026-01-01T00:00:00.000',
        'quote': 'x',
      }),
      jsonEncode(
        FavoriteMoment(
          id: 'good',
          source: FavoriteMomentSource.coffee,
          sourceRef: 'c1',
          savedAt: DateTime(2026, 1, 2),
          occurredAt: DateTime(2026, 1, 2),
          quote: 'cup',
        ).toJson(),
      ),
    ]);
    final all = await repo.getAll();
    expect(all.length, 1);
    expect(all.single.source, FavoriteMomentSource.coffee);
  });

  test('corrupt birth chart and surface memory load safely', () async {
    await storage.setString('birth_chart_latest', '{not-json');
    expect(await LocalBirthChartRepository(storage).getLatest(), isNull);

    await storage.setStringList(DiscoverySurfaceMemory.key, [
      'broken',
      '{"theme":"t1","surface":"home","at":"2026-01-01T00:00:00.000"}',
    ]);
    expect(DiscoverySurfaceMemory(storage).all(), isNotEmpty);
  });

  test('account wipe clears content favorites', () async {
    await storage.setStringList('content_favorites_tarot', const ['a']);
    await storage.setStringList('content_favorites_dream', const ['b']);
    await UserLocalDataWipe.run(storage, secureStorage: secure);
    expect(storage.getStringList('content_favorites_tarot'), isNull);
    expect(storage.getStringList('content_favorites_dream'), isNull);
  });

  test('ephemeral storage promotes writes into SharedPreferences', () async {
    SharedPreferences.setMockInitialValues({});
    final ephemeral = LocalStorage.ephemeral();
    await ephemeral.setInt(GemWalletStore.balanceKey, 42);
    await ephemeral.setString('settings_language', 'en');
    expect(await ephemeral.tryPromote(), isTrue);
    expect(ephemeral.isEphemeral, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt(GemWalletStore.balanceKey), 42);
    expect(prefs.getString('settings_language'), 'en');
  });

  test('account wipe clears deepen daily claim and intelligence index', () async {
    await FirstReadingOrDeepen.markEligible(storage, 'sess-a');
    await storage.setString(FirstReadingOrDeepen.sessionKey, 'sess-a');
    await storage.setBool(FirstReadingOrDeepen.consumedKey, true);
    await storage.setString(DailyRewardsService.claimedKey, '2026-08-31');
    await storage.setString(AstrologyPreferencesStore.signKey, 'leo');
    await IntelligenceIndexStore(storage).save(
      IntelligenceIndexMeta(
        schemaVersion: 1,
        builtAt: DateTime(2026, 8, 31),
        counts: const IntelligenceFacetCounts(
          readings: 1,
          favoriteCards: 0,
          recurringThemes: 0,
          reflections: 0,
          conversations: 0,
          ritualDays: 0,
        ),
      ),
    );

    await UserLocalDataWipe.run(storage, secureStorage: secure);

    expect(FirstReadingOrDeepen.eligibleSessionId(storage), isNull);
    expect(FirstReadingOrDeepen.isConsumed(storage), isFalse);
    expect(storage.getString(DailyRewardsService.claimedKey), isNull);
    expect(storage.getString(AstrologyPreferencesStore.signKey), isNull);
    expect(IntelligenceIndexStore(storage).load(), isNull);
  });

  test('account wipe deletes profile photo file and key', () async {
    final dir = await Directory.systemTemp.createTemp('oracly-photo-wipe');
    final photo = File('${dir.path}/photo.jpg');
    await photo.writeAsBytes(const [1, 2, 3]);
    await storage.setString(ProfilePhotoStore.key, photo.path);

    await UserLocalDataWipe.run(storage, secureStorage: secure);

    expect(storage.getString(ProfilePhotoStore.key), isNull);
    expect(photo.existsSync(), isFalse);
  });

  test('gem starter can grant again after wipe with fresh grant instance',
      () async {
    final wallet = GemWalletService(GemWalletStore(storage));
    final starter = GemStarterGrant(wallet, storage);
    expect(await starter.ensureOnce(), isTrue);
    expect(await starter.ensureOnce(), isFalse);

    await UserLocalDataWipe.run(storage, secureStorage: secure);

    final afterWipe = GemStarterGrant(wallet, storage);
    expect(await afterWipe.ensureOnce(), isTrue);
    expect(wallet.balance, GemEconomy.starterGrant);
  });

  test('account switch wipes user-bound keys for next owner', () async {
    final isolation = UserLocalDataIsolation(
      storage,
      secureStorage: secure,
    );
    await isolation.onSignedIn('owner-a');
    await storage.setString(DailyRewardsService.claimedKey, '2026-08-31');
    await storage.setString(FirstReadingOrDeepen.sessionKey, 'deepen-a');

    await isolation.onSignedIn('owner-b');

    expect(storage.getString(DailyRewardsService.claimedKey), isNull);
    expect(FirstReadingOrDeepen.eligibleSessionId(storage), isNull);
    expect(isolation.localOwnerId, 'owner-b');
  });

  test('corrupt JSON rows are skipped without crashing stores', () async {
    await storage.setStringList(CoffeeReadingStore.key, const ['{bad']);
    await storage.setStringList(PalmReadingStore.key, const ['not-json']);
    await storage.setStringList('dream_records', const ['broken']);
    await storage.setStringList('astrology_history', const ['{']);
    await storage.setStringList('ai_conversations', const ['[]']);

    expect(CoffeeReadingStore(storage).all(), isEmpty);
    expect(PalmReadingStore(storage).all(), isEmpty);
    expect(await LocalDreamRepository(storage).getAll(), isEmpty);
    expect(await LocalAstrologyRepository(storage).getHistory(), isEmpty);
    expect(await LocalAiConversationRepository(storage).getAll(), isEmpty);
    expect(IntelligenceIndexStore(storage).load(), isNull);
    await storage.setString(IntelligenceIndexStore.key, '{bad');
    expect(IntelligenceIndexStore(storage).load(), isNull);
  });

  test('astrology save replaces same id instead of duplicating', () async {
    final repo = LocalAstrologyRepository(storage);
    final first = await repo.getDailyHoroscope('leo');
    expect(first, isNotNull);
    await repo.save(first!);
    await repo.save(first);

    final history = await repo.getHistory();
    expect(history.length, 1);
    expect(history.single.id, first.id);
  });

  test('privacy discovery clear removes tarot session stores', () async {
    await storage.setStringList(TarotLocalDataSource.historyKey, const ['t1']);
    await storage.setString(TarotLocalDataSource.activeKey, 'active');

    await PrivacyDiscoveryClear.run(
      storage: storage,
      history: HistoryService(MockHistoryRepository(storage)),
      birthCharts: LocalBirthChartRepository(storage),
    );

    expect(storage.getStringList(TarotLocalDataSource.historyKey), isEmpty);
    expect(storage.getString(TarotLocalDataSource.activeKey), isNull);
  });
}
