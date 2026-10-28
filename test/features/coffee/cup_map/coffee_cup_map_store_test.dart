/// Fincan Haritası persistence in the durable, backup-excluded location:
/// restart and cache-purge survival, every kept file confirmed excluded,
/// nothing user-made left in SharedPreferences, fail-closed writes, owner
/// isolation, validated pins, deletion, the keep-photos choice, the keeper,
/// and migration of `2e85526d` records out of the evictable cache.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_checksum.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_slot.dart';
import 'package:oracly_new/features/coffee/cup_map/models/coffee_cup_map_record.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_consent.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_keeper.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_location.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_store.dart';

import '../../../support/coffee_cup_map_test_support.dart';

Matcher _rejects(CoffeeCupMapRejection reason) => throwsA(
      isA<CoffeeCupMapException>().having((e) => e.reason, 'reason', reason),
    );

class _NoPlatformLocation extends CoffeeCupMapLocation {
  @override
  Future<Directory> directory() async =>
      throw UnsupportedError('no cup map storage here');
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

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('cup_map_store_');
    paths = await installCupMapPaths(temp);
    storage = await ownedStorage('owner-a');
    await CoffeeCupMapConsent(storage).setKeepPhotos(true);
  });

  tearDown(() async {
    CoffeeCupMapLocation.instance = const MethodChannelCoffeeCupMapLocation();
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  Future<List<CoffeeCupMapPhoto>> keepThree(String readingId) async {
    await CoffeeCupMapKeeper(storage).keep(
      resultId: readingId,
      submissionOwnerId: 'owner-a',
      assets: [
        for (final slot in coffeeV3CanonicalSlotOrder)
          await v3WorkingAsset(temp.path, slot),
      ],
    );
    return (await CoffeeCupMapStore(storage).load(readingId))!.photos;
  }

  group('durable, backup-excluded storage', () {
    test('a map with pins and notes survives an app restart', () async {
      await keepThree('r1');
      await CoffeeCupMapStore(storage).addPin(
        readingId: 'r1',
        slot: CoffeeV3PhotoSlot.cupViewB,
        x: 0.125,
        y: 0.875,
        note: '  sapın yanındaki koyu iz  ',
      );
      // A new process: fresh store, fresh bridge, same app directory.
      CoffeeCupMapLocation.instance = FakeCupMapLocation(temp.path);
      final reopened = (await CoffeeCupMapStore(storage).load('r1'))!;
      final pin = reopened.pins.single;
      expect(pin.x, 0.125);
      expect(pin.y, 0.875);
      expect(pin.note, 'sapın yanındaki koyu iz');
      for (final photo in reopened.photos) {
        expect(File(photo.path).existsSync(), isTrue);
      }
    });

    test('clearing the app cache does not touch the map', () async {
      final photos = await keepThree('r-cache');
      final cache = Directory(paths.cache);
      if (cache.existsSync()) cache.deleteSync(recursive: true);
      final record = (await CoffeeCupMapStore(storage).load('r-cache'))!;
      expect(record.photos, hasLength(3));
      for (final photo in photos) {
        expect(File(photo.path).existsSync(), isTrue);
        expect(photo.path, startsWith(paths.location.path));
      }
    });

    test('every kept file is confirmed excluded; prefs hold no map data',
        () async {
      await keepThree('r-audit');
      await CoffeeCupMapStore(storage).addPin(
        readingId: 'r-audit',
        slot: CoffeeV3PhotoSlot.saucer,
        x: 0.4,
        y: 0.6,
        note: 'tabaktaki halka',
      );
      final audit = paths.location.audit();
      expect(audit.keys.where((p) => p.endsWith(CoffeeCupMapStore.fileName)),
          hasLength(1));
      expect(audit.keys.where((p) => p.endsWith('.tmp')), isEmpty);
      expect(audit, hasLength(4)); // 3 photos + the map file
      expect(audit.values.every((excluded) => excluded), isTrue);
      expect(storage.getString(CoffeeCupMapStore.legacyKey), isNull);
      for (final key in storage.keys) {
        expect('${storage.getString(key)}', isNot(contains('tabaktaki')));
      }
    });

    test('a platform that cannot exclude keeps nothing and changes nothing',
        () async {
      await keepThree('r-before');
      final before = File(
        '${paths.location.path}/${CoffeeCupMapStore.fileName}',
      ).readAsStringSync();
      paths.location.refuseExclusion = true;
      await CoffeeCupMapKeeper(storage).keep(
        resultId: 'r-refused',
        submissionOwnerId: 'owner-a',
        assets: [await v3WorkingAsset(temp.path, CoffeeV3PhotoSlot.cupViewA)],
      );
      expect(await CoffeeCupMapStore(storage).load('r-refused'), isNull);
      await expectLater(
        CoffeeCupMapStore(storage).addPin(
          readingId: 'r-before',
          slot: CoffeeV3PhotoSlot.saucer,
          x: 0.5,
          y: 0.5,
        ),
        _rejects(CoffeeCupMapRejection.blocked),
      );
      expect(
        File('${paths.location.path}/${CoffeeCupMapStore.fileName}')
            .readAsStringSync(),
        before,
      );
      expect(paths.location.audit(), hasLength(4));
    });

    test('no storage on this platform: nothing shown, nothing kept, clean',
        () async {
      CoffeeCupMapLocation.instance = _NoPlatformLocation();
      await CoffeeCupMapKeeper(storage).keep(
        resultId: 'r-none',
        submissionOwnerId: 'owner-a',
        assets: [await v3WorkingAsset(temp.path, CoffeeV3PhotoSlot.cupViewA)],
      );
      expect(await CoffeeCupMapStore(storage).load('r-none'), isNull);
      expect(await CoffeeCupMapStore.purgeStrict(storage), isTrue);
    });

    test('an unreadable map file is never shown and never overwritten',
        () async {
      final file = File('${paths.location.path}/${CoffeeCupMapStore.fileName}');
      (await paths.location.directory()).createSync(recursive: true);
      file.writeAsStringSync('{"schemaVersion":7}');
      final store = CoffeeCupMapStore(storage);
      expect(await store.load('r1'), isNull);
      await expectLater(
        store.createIfAbsent(
          ownerId: 'owner-a',
          readingId: 'r1',
          photos: const [
            CoffeeCupMapPhoto(
              slot: CoffeeV3PhotoSlot.saucer,
              path: '/s.jpg',
              sha256: 's',
            ),
          ],
        ),
        _rejects(CoffeeCupMapRejection.blocked),
      );
      expect(file.readAsStringSync(), '{"schemaVersion":7}');
    });
  });

  group('pins and owners', () {
    setUp(() => keepThree('r1'));

    test('a map is created once and never replaced', () async {
      final store = CoffeeCupMapStore(storage);
      await store.addPin(
        readingId: 'r1',
        slot: CoffeeV3PhotoSlot.saucer,
        x: 0.5,
        y: 0.5,
      );
      final again = await store.createIfAbsent(
        ownerId: 'owner-a',
        readingId: 'r1',
        photos: (await store.load('r1'))!.photos.take(1).toList(),
      );
      expect(again, isFalse);
      final record = (await store.load('r1'))!;
      expect(record.photos, hasLength(3));
      expect(record.pins, hasLength(1));
    });

    test('the same place on one photo is one pin; bounds and limits hold',
        () async {
      final store = CoffeeCupMapStore(storage);
      await store.addPin(
        readingId: 'r1',
        slot: CoffeeV3PhotoSlot.cupViewA,
        x: 0.40,
        y: 0.40,
      );
      await expectLater(
        store.addPin(
          readingId: 'r1',
          slot: CoffeeV3PhotoSlot.cupViewA,
          x: 0.41,
          y: 0.42,
        ),
        _rejects(CoffeeCupMapRejection.samePlace),
      );
      for (final bad in [-0.01, 1.01, double.nan, double.infinity]) {
        await expectLater(
          store.addPin(
            readingId: 'r1',
            slot: CoffeeV3PhotoSlot.saucer,
            x: bad,
            y: 0.5,
          ),
          _rejects(CoffeeCupMapRejection.outOfBounds),
        );
      }
      for (var i = 0; i < CoffeeCupMapLimits.maxPinsPerPhoto; i++) {
        await store.addPin(
          readingId: 'r1',
          slot: CoffeeV3PhotoSlot.saucer,
          x: 0.05 + i * 0.07,
          y: 0.5,
        );
      }
      await expectLater(
        store.addPin(
          readingId: 'r1',
          slot: CoffeeV3PhotoSlot.saucer,
          x: 0.5,
          y: 0.95,
        ),
        _rejects(CoffeeCupMapRejection.limitReached),
      );
    });

    test('writes started together never overwrite each other', () async {
      final store = CoffeeCupMapStore(storage);
      await Future.wait([
        for (var i = 0; i < 4; i++)
          store.addPin(
            readingId: 'r1',
            slot: CoffeeV3PhotoSlot.cupViewA,
            x: 0.1 + i * 0.2,
            y: 0.5,
            note: 'eş zamanlı $i',
          ),
      ]);
      expect((await store.load('r1'))!.pins, hasLength(4));
    });

    test('notes are optional, trimmed, capped; empty clears; pins delete',
        () async {
      final store = CoffeeCupMapStore(storage);
      final added = await store.addPin(
        readingId: 'r1',
        slot: CoffeeV3PhotoSlot.cupViewA,
        x: 0.3,
        y: 0.3,
      );
      final id = added.pins.single.id;
      final long = 'ı' * (CoffeeCupMapLimits.maxNoteLength + 30);
      var record = await store.setNote(readingId: 'r1', pinId: id, note: long);
      expect(record.pins.single.note!.length, CoffeeCupMapLimits.maxNoteLength);
      record = await store.setNote(readingId: 'r1', pinId: id, note: '   ');
      expect(record.pins.single.note, isNull);
      record = await store.removePin(readingId: 'r1', pinId: id);
      expect(record.pins, isEmpty);
    });

    test('another owner can neither see, change nor delete the map', () async {
      await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-b');
      final other = CoffeeCupMapStore(storage);
      expect(await other.load('r1'), isNull);
      await expectLater(
        other.addPin(
          readingId: 'r1',
          slot: CoffeeV3PhotoSlot.saucer,
          x: 0.5,
          y: 0.5,
        ),
        _rejects(CoffeeCupMapRejection.notFound),
      );
      await expectLater(
        other.deleteMap('r1'),
        _rejects(CoffeeCupMapRejection.notFound),
      );
      await storage.remove(UserLocalDataIsolation.ownerKey);
      expect(await CoffeeCupMapStore(storage).load('r1'), isNull);
      await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-a');
      expect(await CoffeeCupMapStore(storage).load('r1'), isNotNull);
    });
  });

  group('per-reading delete', () {
    test('removes that reading\'s photos, pins and notes only', () async {
      final doomed = await keepThree('r-del');
      await keepThree('r-keep');
      final store = CoffeeCupMapStore(storage);
      await store.addPin(
        readingId: 'r-del',
        slot: CoffeeV3PhotoSlot.saucer,
        x: 0.5,
        y: 0.5,
        note: 'silinecek not',
      );
      await store.deleteMap('r-del');
      expect(await store.load('r-del'), isNull);
      for (final photo in doomed) {
        expect(File(photo.path).existsSync(), isFalse);
      }
      expect((await store.load('r-keep'))!.photos, hasLength(3));
      final file = File('${paths.location.path}/${CoffeeCupMapStore.fileName}');
      expect(file.readAsStringSync(), isNot(contains('silinecek')));
      expect(paths.location.audit(), hasLength(4));
    });

    test('a photo that cannot be deleted keeps the map; a retry finishes',
        () async {
      final photos = await keepThree('r-stuck');
      final stuck = CoffeeCupMapStore(storage, deletePhoto: (_) async => false);
      await expectLater(stuck.deleteMap('r-stuck'), throwsStateError);
      expect(await CoffeeCupMapStore(storage).load('r-stuck'), isNotNull);
      await CoffeeCupMapStore(storage).deleteMap('r-stuck');
      expect(await CoffeeCupMapStore(storage).load('r-stuck'), isNull);
      for (final photo in photos) {
        expect(File(photo.path).existsSync(), isFalse);
      }
    });
  });

  group('keeper', () {
    test('without the keep-photos choice nothing is kept', () async {
      await CoffeeCupMapConsent(storage).setKeepPhotos(false);
      await keepThree('r-off').catchError((_) => <CoffeeCupMapPhoto>[]);
      await storage.remove(CoffeeCupMapConsent.key);
      await CoffeeCupMapKeeper(storage).keep(
        resultId: 'r-never-asked',
        submissionOwnerId: 'owner-a',
        assets: [await v3WorkingAsset(temp.path, CoffeeV3PhotoSlot.cupViewA)],
      );
      expect(paths.location.audit(), isEmpty);
    });

    test('keeps the three verified photos byte-for-byte', () async {
      final assets = [
        for (final slot in coffeeV3CanonicalSlotOrder)
          await v3WorkingAsset(temp.path, slot),
      ];
      await CoffeeCupMapKeeper(storage).keep(
        resultId: 'r-bytes',
        submissionOwnerId: 'owner-a',
        assets: assets,
      );
      final record = (await CoffeeCupMapStore(storage).load('r-bytes'))!;
      expect(record.photos.map((p) => p.slot), coffeeV3CanonicalSlotOrder);
      for (final photo in record.photos) {
        final source = assets.firstWhere((a) => a.slot == photo.slot);
        expect(photo.sha256, source.sha256);
        expect(
          File(photo.path).readAsBytesSync(),
          File(source.path).readAsBytesSync(),
        );
      }
    });

    test('a changed photo or another owner is never kept', () async {
      final a = await v3WorkingAsset(temp.path, CoffeeV3PhotoSlot.cupViewA);
      await File(a.path).writeAsBytes([1, 2, 3], mode: FileMode.append);
      await CoffeeCupMapKeeper(storage).keep(
        resultId: 'r-changed',
        submissionOwnerId: 'owner-a',
        assets: [a],
      );
      await CoffeeCupMapKeeper(storage).keep(
        resultId: 'r-other',
        submissionOwnerId: 'owner-x',
        assets: [await v3WorkingAsset(temp.path, CoffeeV3PhotoSlot.saucer)],
      );
      expect(await CoffeeCupMapStore(storage).load('r-changed'), isNull);
      expect(await CoffeeCupMapStore(storage).load('r-other'), isNull);
      expect(paths.location.audit(), isEmpty);
    });

    test('a repeated handoff never replaces the map or its pins', () async {
      await keepThree('r-twice');
      await CoffeeCupMapStore(storage).addPin(
        readingId: 'r-twice',
        slot: CoffeeV3PhotoSlot.cupViewA,
        x: 0.2,
        y: 0.2,
      );
      await keepThree('r-twice');
      expect(
        (await CoffeeCupMapStore(storage).load('r-twice'))!.pins,
        hasLength(1),
      );
      expect(paths.location.audit(), hasLength(4));
    });
  });

  group('migration from 2e85526d (prefs + evictable cache)', () {
    Future<Map<String, String>> legacyCachePhotos() async {
      final dir = Directory('${paths.cache}/coffee_cup_map')
        ..createSync(recursive: true);
      return {
        for (final slot in coffeeV3CanonicalSlotOrder)
          slot.wireValue: (await File(cupMapFixturePhoto)
                  .copy('${dir.path}/legacy_${slot.wireValue}.jpg'))
              .path,
      };
    }

    Future<void> writeLegacy(
      Map<String, String> cached, {
      String? sha,
      bool evictSaucer = false,
    }) async {
      final real = await CoffeeV2Checksum.sha256OfFile(cupMapFixturePhoto);
      if (evictSaucer) File(cached['v3_saucer_view']!).deleteSync();
      await storage.setString(
        CoffeeCupMapStore.legacyKey,
        jsonEncode({
          'schemaVersion': 1,
          'maps': {
            'r-old': {
              'ownerId': 'owner-a',
              'readingId': 'r-old',
              'createdAt': '2026-10-27T18:00:00Z',
              'photos': [
                for (final slot in coffeeV3CanonicalSlotOrder)
                  {
                    'slot': slot.wireValue,
                    'path': cached[slot.wireValue],
                    'sha256': sha ?? real,
                  },
              ],
              'pins': [
                {
                  'id': 'pin_old',
                  'slot': 'v3_saucer_view',
                  'x': 0.3,
                  'y': 0.7,
                  'note': 'eski notum',
                  'createdAt': '2026-10-27T18:01:00Z',
                },
              ],
            },
          },
        }),
      );
    }

    test('moves photos, pins and notes into durable storage', () async {
      final cached = await legacyCachePhotos();
      await writeLegacy(cached);
      final record = (await CoffeeCupMapStore(storage).load('r-old'))!;
      expect(record.pins.single.note, 'eski notum');
      for (final photo in record.photos) {
        expect(photo.path, startsWith(paths.location.path));
        expect(File(photo.path).existsSync(), isTrue);
      }
      expect(storage.getString(CoffeeCupMapStore.legacyKey), isNull);
      for (final old in cached.values) {
        expect(File(old).existsSync(), isFalse);
      }
      expect(paths.location.audit().values.every((e) => e), isTrue);
    });

    test('an already-evicted photo stays listed as missing, pins kept',
        () async {
      final cached = await legacyCachePhotos();
      await writeLegacy(cached, evictSaucer: true);
      final record = (await CoffeeCupMapStore(storage).load('r-old'))!;
      final saucer = record.photoFor(CoffeeV3PhotoSlot.saucer)!;
      expect(File(saucer.path).existsSync(), isFalse);
      expect(record.pinsFor(CoffeeV3PhotoSlot.saucer), hasLength(1));
      expect(
        File(record.photoFor(CoffeeV3PhotoSlot.cupViewA)!.path).existsSync(),
        isTrue,
      );
    });

    test('a failed migration keeps the old data intact and retries later',
        () async {
      final cached = await legacyCachePhotos();
      await writeLegacy(cached, sha: 'not-the-real-checksum');
      final rawBefore = storage.getString(CoffeeCupMapStore.legacyKey);
      expect(await CoffeeCupMapStore(storage).load('r-old'), isNull);
      expect(storage.getString(CoffeeCupMapStore.legacyKey), rawBefore);
      for (final old in cached.values) {
        expect(File(old).existsSync(), isTrue);
      }
      expect(paths.location.audit(), isEmpty);

      // Next launch, with the record readable again: it moves.
      await writeLegacy(cached);
      expect(await CoffeeCupMapStore(storage).load('r-old'), isNotNull);
      expect(storage.getString(CoffeeCupMapStore.legacyKey), isNull);
    });
  });

  group('keep-photos choice', () {
    test('off by default, per owner, and unreadable data means off', () async {
      final own = await ownedStorage('owner-c');
      final consent = CoffeeCupMapConsent(own);
      expect(consent.keepPhotos, isFalse);
      expect(await consent.setKeepPhotos(true), isTrue);
      expect(CoffeeCupMapConsent(own).keepPhotos, isTrue);
      await own.setString(UserLocalDataIsolation.ownerKey, 'owner-d');
      expect(CoffeeCupMapConsent(own).keepPhotos, isFalse);
      await own.setString(UserLocalDataIsolation.ownerKey, 'owner-c');
      await consent.setKeepPhotos(false);
      expect(consent.keepPhotos, isFalse);
      await own.setString(CoffeeCupMapConsent.key, '{broken');
      expect(consent.keepPhotos, isFalse);
      await own.remove(UserLocalDataIsolation.ownerKey);
      expect(consent.keepPhotos, isFalse);
      expect(await consent.setKeepPhotos(true), isFalse);
    });
  });
}
