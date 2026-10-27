/// Fincan Haritası privacy: the account-boundary wipe removes the kept
/// photos, the maps and the keep-photos choice; the discovery history clear
/// removes the photos and the maps (the choice is a setting and stays);
/// kept photos live in the app cache directory, never next to the backed-up
/// `coffee_images` archive.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/services/history_service.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_slot.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_consent.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_keeper.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_store.dart';
import 'package:oracly_new/features/privacy/services/privacy_discovery_clear.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/coffee_cup_map_test_support.dart';
import '../../birth_chart/evidence/test_birth_owner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late CupMapPaths paths;
  late LocalStorage storage;
  late List<String> kept;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-p');
    temp = await Directory.systemTemp.createTemp('cup_map_privacy_');
    paths = await installCupMapPaths(temp);
    await CoffeeCupMapConsent(storage).setKeepPhotos(true);
    await CoffeeCupMapKeeper(storage).keep(
      resultId: 'r-private',
      submissionOwnerId: 'owner-p',
      assets: [
        for (final slot in coffeeV3CanonicalSlotOrder)
          await v3WorkingAsset(temp.path, slot),
      ],
    );
    kept = CoffeeCupMapStore.archivedPaths(storage);
    expect(kept, hasLength(3));
    for (final path in kept) {
      expect(File(path).existsSync(), isTrue);
      expect(path, startsWith(paths.cache));
      expect(path, isNot(startsWith(paths.documents)));
    }
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('account wipe removes the kept photos, the map and the choice',
      () async {
    final result = await UserLocalDataWipe.run(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
    expect(result.failedOperations, isNot(contains(CoffeeCupMapStore.key)));
    expect(result.failedOperations, isNot(contains('coffee_cup_map_photos')));
    expect(storage.getString(CoffeeCupMapStore.key), isNull);
    expect(storage.getString(CoffeeCupMapConsent.key), isNull);
    for (final path in kept) {
      expect(File(path).existsSync(), isFalse);
    }
  });

  test('history clear removes photos and maps; the choice stays', () async {
    await PrivacyDiscoveryClear.run(
      storage: storage,
      history: HistoryService(MockHistoryRepository(storage)),
      birthCharts: testBirthChartRepo(storage),
    );
    expect(storage.getString(CoffeeCupMapStore.key), isNull);
    for (final path in kept) {
      expect(File(path).existsSync(), isFalse);
    }
    // (testBirthChartRepo re-stamps the local owner, so read the stored
    // choice itself.)
    expect(storage.getString(CoffeeCupMapConsent.key), contains('owner-p'));
  });
}
