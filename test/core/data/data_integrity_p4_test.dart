/// P4 data integrity audit tests.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_birth_chart_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_user_repository.dart';
import 'package:oracly_new/core/domain/models/user_profile.dart';
import 'package:oracly_new/features/favorite_moments/data/local_favorite_moments_repository.dart';
import 'package:oracly_new/features/favorite_moments/models/favorite_moment.dart';
import 'package:oracly_new/features/gems/data/gem_wallet_store.dart';
import 'package:oracly_new/features/gems/economy/gem_economy.dart';
import 'package:oracly_new/features/gems/services/gem_starter_grant.dart';
import 'package:oracly_new/features/gems/services/gem_wallet_service.dart';
import 'package:oracly_new/features/personal_discovery/data/discovery_surface_memory.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
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
    await UserLocalDataWipe.run(storage);
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
}
