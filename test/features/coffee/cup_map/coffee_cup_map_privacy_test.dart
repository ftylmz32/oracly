/// Fincan Haritası privacy: the account-boundary wipe and the discovery
/// history clear both remove the kept photos from disk AND the map
/// metadata, so nothing of one owner's cup reaches the next.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_slot.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_keeper.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_store.dart';
import 'package:oracly_new/features/privacy/services/discovery_owned_image_wipe.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/coffee_cup_map_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late LocalStorage storage;
  late List<String> kept;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = LocalStorage(await SharedPreferences.getInstance());
    await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-p');
    temp = await Directory.systemTemp.createTemp('cup_map_privacy_');
    await installCupMapPaths(temp);
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
    }
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  test('account wipe removes the kept photos and the map', () async {
    final result = await UserLocalDataWipe.run(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
    expect(result.failedOperations, isNot(contains(CoffeeCupMapStore.key)));
    expect(storage.getString(CoffeeCupMapStore.key), isNull);
    for (final path in kept) {
      expect(File(path).existsSync(), isFalse);
    }
  });

  test('discovery image wipe deletes every kept photo path', () async {
    final result =
        await DiscoveryOwnedImageWipe.wipeCoffeeAndPalmImagesStrict(storage);
    expect(result.metadataMayBeCleared, isTrue);
    for (final path in kept) {
      expect(File(path).existsSync(), isFalse);
    }
  });
}
