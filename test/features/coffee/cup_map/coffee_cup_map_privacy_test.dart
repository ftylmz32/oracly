/// Fincan Haritası privacy: kept photos and the map file live in the
/// durable, backup-excluded directory; the account-boundary wipe removes
/// every file there, the pre-migration cache and record, and the
/// keep-photos choice; the discovery history clear removes the photos and
/// maps (the choice is a setting and stays).
library;

import 'dart:io';

import 'package:flutter/services.dart';
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
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_location.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_store.dart';
import 'package:oracly_new/features/privacy/services/privacy_discovery_clear.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/coffee_cup_map_test_support.dart';
import '../../birth_chart/evidence/test_birth_owner.dart';

/// The bridge answers, but the OS refuses the directory.
class _BrokenLocation extends CoffeeCupMapLocation {
  @override
  Future<Directory> directory() async =>
      throw PlatformException(code: 'cup_map_storage', message: 'io error');
  @override
  Future<bool> excludeFromBackup(String path) async => false;
  @override
  Future<bool> isExcludedFromBackup(String path) async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late CupMapPaths paths;
  late LocalStorage storage;
  late List<String> kept;
  late File legacyPhoto;

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
    kept = await CoffeeCupMapStore.archivedPaths(storage);
    expect(kept, hasLength(3));
    for (final path in kept) {
      expect(File(path).existsSync(), isTrue);
      expect(path, startsWith(paths.location.path));
    }
    expect(cupMapFileText(), isNotNull);
    // A leftover from the pre-migration cache that a wipe must also clear.
    final legacyDir = Directory('${paths.cache}/coffee_cup_map')
      ..createSync(recursive: true);
    legacyPhoto = File('${legacyDir.path}/leftover.jpg')
      ..writeAsBytesSync([1, 2, 3]);
  });

  tearDown(() async {
    CoffeeCupMapLocation.instance = const MethodChannelCoffeeCupMapLocation();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('account wipe removes every kept file, the map and the choice',
      () async {
    final result = await UserLocalDataWipe.run(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
    expect(result.failedOperations, isNot(contains('coffee_cup_map')));
    expect(paths.location.audit(), isEmpty);
    expect(cupMapFileText(), isNull);
    expect(legacyPhoto.existsSync(), isFalse);
    expect(storage.getString(CoffeeCupMapStore.legacyKey), isNull);
    expect(storage.getString(CoffeeCupMapConsent.key), isNull);
    for (final path in kept) {
      expect(File(path).existsSync(), isFalse);
    }
  });

  test('an unreachable storage location is reported, never hidden',
      () async {
    CoffeeCupMapLocation.instance = _BrokenLocation();
    final result = await UserLocalDataWipe.run(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
    expect(result.isComplete, isFalse);
    expect(result.failedOperations, contains('coffee_cup_map'));
    // Nothing was deleted behind the user's back either.
    for (final path in kept) {
      expect(File(path).existsSync(), isTrue);
    }
  });

  test('history clear removes photos and maps; the choice stays', () async {
    await PrivacyDiscoveryClear.run(
      storage: storage,
      history: HistoryService(MockHistoryRepository(storage)),
      birthCharts: testBirthChartRepo(storage),
    );
    expect(paths.location.audit(), isEmpty);
    expect(cupMapFileText(), isNull);
    expect(legacyPhoto.existsSync(), isFalse);
    for (final path in kept) {
      expect(File(path).existsSync(), isFalse);
    }
    // (testBirthChartRepo re-stamps the local owner, so read the stored
    // choice itself.)
    expect(storage.getString(CoffeeCupMapConsent.key), contains('owner-p'));
  });
}
