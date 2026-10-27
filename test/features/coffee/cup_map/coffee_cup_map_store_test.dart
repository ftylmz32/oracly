/// Fincan Haritası persistence: owner isolation, one map per reading that a
/// repeated handoff can never replace, validated pins (bounds, same place,
/// per-photo limit), optional notes, restart round-trip and fail-closed
/// reading of an unreadable payload.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_slot.dart';
import 'package:oracly_new/features/coffee/cup_map/models/coffee_cup_map_record.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_keeper.dart';
import 'package:oracly_new/features/coffee/cup_map/services/coffee_cup_map_store.dart';

import '../../../support/coffee_cup_map_test_support.dart';

const _photos = [
  CoffeeCupMapPhoto(slot: CoffeeV3PhotoSlot.cupViewA, path: '/a.jpg', sha256: 'a'),
  CoffeeCupMapPhoto(slot: CoffeeV3PhotoSlot.cupViewB, path: '/b.jpg', sha256: 'b'),
  CoffeeCupMapPhoto(slot: CoffeeV3PhotoSlot.saucer, path: '/s.jpg', sha256: 's'),
];

Matcher _rejects(CoffeeCupMapRejection reason) => throwsA(
      isA<CoffeeCupMapException>().having((e) => e.reason, 'reason', reason),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('store', () {
    late LocalStorage storage;
    late CoffeeCupMapStore store;

    setUp(() async {
      storage = await ownedStorage('owner-a');
      store = CoffeeCupMapStore(storage);
      await store.createIfAbsent(
        ownerId: 'owner-a',
        readingId: 'r1',
        photos: _photos,
      );
    });

    test('a map is created once and never replaced', () async {
      await store.addPin(
        readingId: 'r1',
        slot: CoffeeV3PhotoSlot.saucer,
        x: 0.5,
        y: 0.5,
      );
      final again = await store.createIfAbsent(
        ownerId: 'owner-a',
        readingId: 'r1',
        photos: _photos.take(1).toList(),
      );
      expect(again, isFalse);
      final record = store.load('r1')!;
      expect(record.photos, hasLength(3));
      expect(record.pins, hasLength(1));
    });

    test('pins keep exact normalized coordinates and survive a restart',
        () async {
      await store.addPin(
        readingId: 'r1',
        slot: CoffeeV3PhotoSlot.cupViewB,
        x: 0.125,
        y: 0.875,
        note: '  sapın yanındaki koyu iz  ',
      );
      final reopened = CoffeeCupMapStore(storage).load('r1')!;
      final pin = reopened.pins.single;
      expect(pin.slot, CoffeeV3PhotoSlot.cupViewB);
      expect(pin.x, 0.125);
      expect(pin.y, 0.875);
      expect(pin.note, 'sapın yanındaki koyu iz');
      expect(reopened.pinsFor(CoffeeV3PhotoSlot.cupViewA), isEmpty);
    });

    test('the same place on the same photo is one pin; another photo is not',
        () async {
      await store.addPin(
        readingId: 'r1',
        slot: CoffeeV3PhotoSlot.cupViewA,
        x: 0.40,
        y: 0.40,
      );
      expect(
        () => store.addPin(
          readingId: 'r1',
          slot: CoffeeV3PhotoSlot.cupViewA,
          x: 0.41,
          y: 0.42,
        ),
        _rejects(CoffeeCupMapRejection.samePlace),
      );
      await store.addPin(
        readingId: 'r1',
        slot: CoffeeV3PhotoSlot.cupViewB,
        x: 0.40,
        y: 0.40,
      );
      expect(store.load('r1')!.pins, hasLength(2));
    });

    test('out-of-image, unknown photo and the per-photo limit are refused',
        () async {
      for (final bad in [-0.01, 1.01, double.nan, double.infinity]) {
        expect(
          () => store.addPin(
            readingId: 'r1',
            slot: CoffeeV3PhotoSlot.saucer,
            x: bad,
            y: 0.5,
          ),
          _rejects(CoffeeCupMapRejection.outOfBounds),
        );
      }
      await CoffeeCupMapStore(storage).createIfAbsent(
        ownerId: 'owner-a',
        readingId: 'r2',
        photos: _photos.take(1).toList(),
      );
      expect(
        () => store.addPin(
          readingId: 'r2',
          slot: CoffeeV3PhotoSlot.saucer,
          x: 0.5,
          y: 0.5,
        ),
        _rejects(CoffeeCupMapRejection.noSuchPhoto),
      );
      for (var i = 0; i < CoffeeCupMapLimits.maxPinsPerPhoto; i++) {
        await store.addPin(
          readingId: 'r1',
          slot: CoffeeV3PhotoSlot.saucer,
          x: 0.05 + i * 0.07,
          y: 0.5,
        );
      }
      expect(
        () => store.addPin(
          readingId: 'r1',
          slot: CoffeeV3PhotoSlot.saucer,
          x: 0.5,
          y: 0.95,
        ),
        _rejects(CoffeeCupMapRejection.limitReached),
      );
    });

    test('notes are optional, trimmed, capped; empty clears; pins delete',
        () async {
      final added = await store.addPin(
        readingId: 'r1',
        slot: CoffeeV3PhotoSlot.cupViewA,
        x: 0.3,
        y: 0.3,
      );
      final id = added.pins.single.id;
      expect(added.pins.single.hasNote, isFalse);
      final long = 'ı' * (CoffeeCupMapLimits.maxNoteLength + 30);
      var record = await store.setNote(readingId: 'r1', pinId: id, note: long);
      expect(record.pins.single.note!.length, CoffeeCupMapLimits.maxNoteLength);
      record = await store.setNote(readingId: 'r1', pinId: id, note: '   ');
      expect(record.pins.single.note, isNull);
      record = await store.removePin(readingId: 'r1', pinId: id);
      expect(record.pins, isEmpty);
    });

    test('another owner can neither see nor change the map', () async {
      await storage.setString(UserLocalDataIsolation.ownerKey, 'owner-b');
      final other = CoffeeCupMapStore(storage);
      expect(other.load('r1'), isNull);
      expect(
        () => other.addPin(
          readingId: 'r1',
          slot: CoffeeV3PhotoSlot.saucer,
          x: 0.5,
          y: 0.5,
        ),
        _rejects(CoffeeCupMapRejection.notFound),
      );
      expect(
        () => other.createIfAbsent(
          ownerId: 'owner-a',
          readingId: 'r9',
          photos: _photos,
        ),
        _rejects(CoffeeCupMapRejection.blocked),
      );
      await storage.remove(UserLocalDataIsolation.ownerKey);
      expect(CoffeeCupMapStore(storage).load('r1'), isNull);
    });

    test('an unreadable payload is never shown and never overwritten',
        () async {
      await storage.setString(CoffeeCupMapStore.key, '{"schemaVersion":7}');
      expect(store.load('r1'), isNull);
      expect(
        () => store.addPin(
          readingId: 'r1',
          slot: CoffeeV3PhotoSlot.saucer,
          x: 0.5,
          y: 0.5,
        ),
        _rejects(CoffeeCupMapRejection.blocked),
      );
      expect(storage.getString(CoffeeCupMapStore.key), '{"schemaVersion":7}');
      expect(CoffeeCupMapStore.archivedPaths(storage), isEmpty);
    });
  });

  group('keeper', () {
    late Directory temp;
    late CupMapPaths paths;
    late LocalStorage storage;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('cup_map_keeper_');
      paths = await installCupMapPaths(temp);
      storage = await ownedStorage('owner-k');
    });

    tearDown(() async {
      if (await temp.exists()) await temp.delete(recursive: true);
    });

    Future<List<String>> archived() async {
      final dir = Directory('${paths.documents}/coffee_images');
      if (!await dir.exists()) return const [];
      return [await for (final f in dir.list()) f.path];
    }

    test('keeps the three verified photos byte-for-byte in the owned archive',
        () async {
      final assets = [
        for (final slot in coffeeV3CanonicalSlotOrder)
          await v3WorkingAsset(temp.path, slot),
      ];
      await CoffeeCupMapKeeper(storage).keep(
        resultId: 'coffee-v3-r1',
        submissionOwnerId: 'owner-k',
        assets: assets,
      );
      final record = CoffeeCupMapStore(storage).load('coffee-v3-r1')!;
      expect(
        record.photos.map((p) => p.slot),
        coffeeV3CanonicalSlotOrder,
      );
      for (final photo in record.photos) {
        expect(photo.path, startsWith(paths.documents));
        expect(photo.path, contains('coffee_images'));
        final source = assets.firstWhere((a) => a.slot == photo.slot);
        expect(photo.sha256, source.sha256);
        expect(
          await File(photo.path).readAsBytes(),
          await File(source.path).readAsBytes(),
        );
      }
      expect(CoffeeCupMapStore.archivedPaths(storage), hasLength(3));
    });

    test('a photo changed after capture is left off the map', () async {
      final a = await v3WorkingAsset(temp.path, CoffeeV3PhotoSlot.cupViewA);
      final b = await v3WorkingAsset(temp.path, CoffeeV3PhotoSlot.cupViewB);
      final s = await v3WorkingAsset(temp.path, CoffeeV3PhotoSlot.saucer);
      await File(b.path).writeAsBytes([1, 2, 3], mode: FileMode.append);
      await CoffeeCupMapKeeper(storage).keep(
        resultId: 'r-changed',
        submissionOwnerId: 'owner-k',
        assets: [a, b, s],
      );
      final record = CoffeeCupMapStore(storage).load('r-changed')!;
      expect(
        record.photos.map((p) => p.slot),
        [CoffeeV3PhotoSlot.cupViewA, CoffeeV3PhotoSlot.saucer],
      );
    });

    test('a different submission owner keeps nothing', () async {
      final a = await v3WorkingAsset(temp.path, CoffeeV3PhotoSlot.cupViewA);
      await CoffeeCupMapKeeper(storage).keep(
        resultId: 'r-other',
        submissionOwnerId: 'owner-x',
        assets: [a],
      );
      expect(CoffeeCupMapStore(storage).load('r-other'), isNull);
      expect(await archived(), isEmpty);
    });

    test('a repeated handoff never replaces the map or its pins', () async {
      final assets = [
        for (final slot in coffeeV3CanonicalSlotOrder)
          await v3WorkingAsset(temp.path, slot),
      ];
      final keeper = CoffeeCupMapKeeper(storage);
      await keeper.keep(
        resultId: 'r-twice',
        submissionOwnerId: 'owner-k',
        assets: assets,
      );
      await CoffeeCupMapStore(storage).addPin(
        readingId: 'r-twice',
        slot: CoffeeV3PhotoSlot.cupViewA,
        x: 0.2,
        y: 0.2,
      );
      await keeper.keep(
        resultId: 'r-twice',
        submissionOwnerId: 'owner-k',
        assets: assets,
      );
      expect(CoffeeCupMapStore(storage).load('r-twice')!.pins, hasLength(1));
      expect(await archived(), hasLength(3));
    });

    test('when the map cannot be written its copies are removed', () async {
      await storage.setString(CoffeeCupMapStore.key, 'not json');
      final a = await v3WorkingAsset(temp.path, CoffeeV3PhotoSlot.cupViewA);
      await CoffeeCupMapKeeper(storage).keep(
        resultId: 'r-blocked',
        submissionOwnerId: 'owner-k',
        assets: [a],
      );
      expect(await archived(), isEmpty);
      expect(storage.getString(CoffeeCupMapStore.key), 'not json');
    });
  });
}
