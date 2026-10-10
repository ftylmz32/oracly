/// Slice 4A — Coffee V3 privacy + persisted-contract hardening:
/// strictly-scoped physical cleanup of app-owned V3 working photos (never
/// originals / V2 / Palm / arbitrary metadata paths), honest account-wipe
/// integration (incomplete cleanup keeps the V3 locator and reports
/// failure), explicit schema versioning with historical-record
/// compatibility, and owner isolation including unowned records.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_checksum.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_asset.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_stage_state.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_submission_record.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_submission_store.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_work_files.dart';
import 'package:oracly_new/features/privacy/services/archive_path_kind.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/coffee_v2_test_support.dart';
import '../../../support/coffee_v3_test_support.dart';
import '../../../support/fake_reading_operation_backend.dart';

/// path_provider that cannot resolve anything (ownership = UNKNOWN).
class _BrokenPathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationSupportPath() async =>
      throw StateError('path_provider unavailable');
  @override
  Future<String?> getApplicationDocumentsPath() async =>
      throw StateError('path_provider unavailable');
}

const _opId = '0000000000000000000000000000abcd';

/// A record exactly as Slice 4 (9084c079) persisted it: no schemaVersion.
Map<String, dynamic> _historicalJson({
  String? ownerId = 'owner-a',
  String? operationId = _opId,
}) =>
    {
      'captureContract': 'four_view_v3',
      'ownerId': ?ownerId,
      'operationId': ?operationId,
      'sourceRequestId': 'coffee-v3-1700000000000',
      'intention': 'Aşk ve ilişkilerim hakkında',
      'resultId': 'coffee-m2-r9',
      'resultPendingAcknowledgement': true,
      'slots': {
        for (final slot in coffeeV3CanonicalSlotOrder)
          slot.wireValue: {
            'asset': CoffeeV3PhotoAsset(
              slot: slot,
              path: '/support/coffee_v3_work/coffee_v3_work_${slot.index}.jpg',
              mimeType: 'image/jpeg',
              sha256: 'sha-${slot.index}',
              sizeBytes: 1000 + slot.index,
            ).toJson(),
            'confirmed': true,
            'stageState':
                slot.index < 2 ? 'staged' : 'not_staged',
          },
      },
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory work;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('coffee_v3_4a_');
    installCoffeeV3SupportRoot(root.path);
    work = Directory('${root.path}/${CoffeeV3WorkFiles.dirName}');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<File> write(String relative) async {
    final f = File('${root.path}/$relative');
    await f.parent.create(recursive: true);
    await f.writeAsBytes(plainJpegBytes(totalSize: 4096));
    return f;
  }

  group('ownership boundary', () {
    test('only prefixed files strictly inside coffee_v3_work are owned', () async {
      final owned = await write('coffee_v3_work/coffee_v3_work_1.jpg');
      final v2 = await write('coffee_v2_work/coffee_v2_work_1.jpg');
      final gallery = await write('DCIM/IMG_0001.jpg');
      final unprefixed = await write('coffee_v3_work/notes.jpg');
      final prefixedOutside = await write('coffee_v3_work_9.jpg');
      final traversal =
          '${root.path}/coffee_v3_work/../coffee_v2_work/coffee_v3_work_x.jpg';
      expect(await CoffeeV3WorkFiles.classify(owned.path), ArchivePathKind.owned);
      for (final p in [
        v2.path,
        gallery.path,
        unprefixed.path,
        prefixedOutside.path,
        traversal,
        '',
        null,
      ]) {
        expect(await CoffeeV3WorkFiles.classify(p), ArchivePathKind.notOwned,
            reason: '$p');
      }
    });

    test('deleteIfOwnedStrict: never touches a not-owned file; missing is fine',
        () async {
      final gallery = await write('DCIM/IMG_0002.jpg');
      expect(await CoffeeV3WorkFiles.deleteIfOwnedStrict(gallery.path), isTrue);
      expect(await gallery.exists(), isTrue);
      final owned = await write('coffee_v3_work/coffee_v3_work_2.jpg');
      expect(await CoffeeV3WorkFiles.deleteIfOwnedStrict(owned.path), isTrue);
      expect(await owned.exists(), isFalse);
      expect(await CoffeeV3WorkFiles.deleteIfOwnedStrict(owned.path), isTrue);
    });

    test('path_provider failure is UNKNOWN — never claimed as deleted', () async {
      final owned = await write('coffee_v3_work/coffee_v3_work_3.jpg');
      PathProviderPlatform.instance = _BrokenPathProvider();
      expect(await CoffeeV3WorkFiles.classify(owned.path), ArchivePathKind.unknown);
      expect(await CoffeeV3WorkFiles.deleteIfOwnedStrict(owned.path), isFalse);
      expect(await CoffeeV3WorkFiles.purgeStrict(), isFalse);
      expect(await owned.exists(), isTrue);
    });
  });

  group('strict purge', () {
    test('deletes only V3 working copies; repeated purge is idempotent', () async {
      final a = await write('coffee_v3_work/coffee_v3_work_a.jpg');
      final b = await write('coffee_v3_work/coffee_v3_work_b.jpg');
      final foreign = await write('coffee_v3_work/keep_me.txt');
      final nested = await write('coffee_v3_work/coffee_v3_work_dir/inner.jpg');
      final v2 = await write('coffee_v2_work/coffee_v2_work_1.jpg');
      final palm = await write('palm_images/palm_1.jpg');
      final gallery = await write('DCIM/IMG_0003.jpg');

      expect(await CoffeeV3WorkFiles.purgeStrict(), isTrue);
      expect(await a.exists(), isFalse);
      expect(await b.exists(), isFalse);
      for (final kept in [foreign, nested, v2, palm, gallery]) {
        expect(await kept.exists(), isTrue, reason: kept.path);
      }
      expect(await CoffeeV3WorkFiles.purgeStrict(), isTrue);
    });

    test('missing work dir = nothing to clean, and it is not created', () async {
      expect(await work.exists(), isFalse);
      expect(await CoffeeV3WorkFiles.purgeStrict(), isTrue);
      expect(await work.exists(), isFalse);
    });

    test('a failed delete reports incomplete (Windows file lock)', () async {
      final locked = await write('coffee_v3_work/coffee_v3_work_locked.jpg');
      final handle = await locked.open(mode: FileMode.append);
      addTearDown(handle.close);
      final result = await CoffeeV3WorkFiles.purgeStrict();
      if (Platform.isWindows) {
        expect(result, isFalse);
        expect(await locked.exists(), isTrue);
      }
    });
  });

  group('account-boundary wipe (logout / deletion / switch share it)', () {
    Future<LocalStorage> seeded() async {
      SharedPreferences.setMockInitialValues({
        CoffeeV3SubmissionStore.key: jsonEncode(_historicalJson()),
        CoffeeV3SubmissionStore.acknowledgedOperationKey: '{}',
      });
      return LocalStorage(await SharedPreferences.getInstance());
    }

    test('purges V3 working photos, then clears V3 metadata', () async {
      final storage = await seeded();
      final v3 = await write('coffee_v3_work/coffee_v3_work_w.jpg');
      // Slice 4B: V2 working copies are purged by their OWN wipe step; the
      // V3 purge itself never touches them (see "strict purge" above).
      final palm = await write('palm_images/palm_w.jpg');
      final gallery = await write('DCIM/IMG_0004.jpg');
      final result = await UserLocalDataWipe.run(
        storage,
        secureStorage: InMemorySecureStorage(),
      );
      expect(result.failedOperations, isNot(contains('coffee_v3_work_images')));
      expect(result.failedOperations, isNot(contains(CoffeeV3SubmissionStore.key)));
      expect(await v3.exists(), isFalse);
      expect(await palm.exists(), isTrue);
      expect(await gallery.exists(), isTrue);
      expect(storage.getString(CoffeeV3SubmissionStore.key), isNull);
      expect(storage.getString(CoffeeV3SubmissionStore.acknowledgedOperationKey),
          isNull);
    });

    test('incomplete cleanup keeps the V3 locator and is reported, retry works',
        () async {
      final storage = await seeded();
      final v3 = await write('coffee_v3_work/coffee_v3_work_r.jpg');
      PathProviderPlatform.instance = _BrokenPathProvider();
      final failed = await UserLocalDataWipe.run(
        storage,
        secureStorage: InMemorySecureStorage(),
      );
      expect(failed.isComplete, isFalse);
      expect(failed.failedOperations, contains('coffee_v3_work_images'));
      expect(failed.failedOperations, contains(CoffeeV3SubmissionStore.key));
      expect(storage.getString(CoffeeV3SubmissionStore.key), isNotNull);
      expect(await v3.exists(), isTrue);

      installCoffeeV3SupportRoot(root.path);
      final retry = await UserLocalDataWipe.run(
        storage,
        secureStorage: InMemorySecureStorage(),
      );
      expect(retry.failedOperations, isNot(contains('coffee_v3_work_images')));
      expect(await v3.exists(), isFalse);
      expect(storage.getString(CoffeeV3SubmissionStore.key), isNull);
    });
  });

  group('schema compatibility', () {
    test('historical Slice-4 record (no schemaVersion) is accepted verbatim',
        () {
      final record = CoffeeV3SubmissionRecord.fromJson(
        jsonDecode(jsonEncode(_historicalJson())),
      );
      expect(record.ownerId, 'owner-a');
      expect(record.operationId, _opId);
      expect(record.sourceRequestId, 'coffee-v3-1700000000000');
      expect(record.intention, 'Aşk ve ilişkilerim hakkında');
      expect(record.resultId, 'coffee-m2-r9');
      expect(record.resultPendingAcknowledgement, isTrue);
      for (final slot in coffeeV3CanonicalSlotOrder) {
        expect(record.slots[slot]!.asset!.sha256, 'sha-${slot.index}');
        expect(record.slots[slot]!.confirmed, isTrue);
        expect(
          record.slots[slot]!.stageState,
          slot.index < 2 ? CoffeeV3StageState.staged : CoffeeV3StageState.notStaged,
        );
      }
      // Rewritten with the explicit version; nothing else changes.
      final upgraded = record.toJson();
      expect(upgraded['schemaVersion'], 1);
      final expected = Map<String, dynamic>.from(_historicalJson())
        ..['schemaVersion'] = 1;
      expect(jsonDecode(jsonEncode(upgraded)), jsonDecode(jsonEncode(expected)));
    });

    test('unknown / malformed schema versions fail closed', () {
      for (final bad in <Object?>[2, 0, -1, '1', 1.5, null]) {
        final json = _historicalJson()..['schemaVersion'] = bad;
        expect(() => CoffeeV3SubmissionRecord.fromJson(json),
            throwsFormatException, reason: '$bad');
      }
    });

    test('store: historical ACTIVE stays active; future schema never overwritten',
        () async {
      final storage = LocalStorage.ephemeral();
      await storage.setString(
          CoffeeV3SubmissionStore.key, jsonEncode(_historicalJson()));
      final store =
          CoffeeV3SubmissionStore(storage, ownerId: 'owner-a', requireOwner: true);
      expect(store.inspect(), CoffeeV3StoredState.active);
      expect(store.load()?.operationId, _opId);

      // Historical ACTIVE restore is verbatim through the controller too.
      final transport = CoffeeV3TestTransport(FakeReadingOperationBackend());
      final controller = CoffeeV3SubmissionController(
        flow: ReadingLiveFlow(
          operations: ReadingOperationGateway(send: transport.send),
          acceleration: ReadingAccelerationClient(send: transport.send),
          send: transport.send,
        ),
        stagedImages: ReadingStagedImageGateway(transport.send),
        store: store,
        creationAllowed: () => true,
      );
      await controller.recoverDraftOrSubmission();
      expect(controller.record.operationId, _opId);
      expect(controller.record.sourceRequestId, 'coffee-v3-1700000000000');
      expect(transport.calls, isEmpty);

      final future = _historicalJson()..['schemaVersion'] = 2;
      await storage.setString(CoffeeV3SubmissionStore.key, jsonEncode(future));
      expect(store.inspect(), CoffeeV3StoredState.blocked);
      expect(store.load(), isNull);
      await expectLater(
        store.save(CoffeeV3SubmissionRecord.empty()),
        throwsStateError,
      );
      await expectLater(store.clearDurable(), throwsStateError);
      expect(
        jsonDecode(storage.getString(CoffeeV3SubmissionStore.key)!)['schemaVersion'],
        2,
      );
      // Never interpreted as / migrated into V2.
      expect(storage.getString('coffee_v2_submission'), isNull);
    });

    test('a normal save upgrades a historical record in place, fields intact',
        () async {
      final storage = LocalStorage.ephemeral();
      final draft = _historicalJson(operationId: null);
      await storage.setString(CoffeeV3SubmissionStore.key, jsonEncode(draft));
      final store =
          CoffeeV3SubmissionStore(storage, ownerId: 'owner-a', requireOwner: true);
      final loaded = store.load()!;
      await store.save(loaded.copyWith(intention: 'Para'));
      final raw = jsonDecode(storage.getString(CoffeeV3SubmissionStore.key)!);
      expect(raw['schemaVersion'], 1);
      expect(raw['ownerId'], 'owner-a');
      expect(raw['sourceRequestId'], 'coffee-v3-1700000000000');
      expect(raw['intention'], 'Para');
      expect((raw['slots'] as Map).length, 4);
    });
  });

  group('owner isolation', () {
    test('an unowned record is never adopted by a signed-in owner', () async {
      final storage = LocalStorage.ephemeral();
      final unowned = _historicalJson(ownerId: null);
      await storage.setString(CoffeeV3SubmissionStore.key, jsonEncode(unowned));
      final store =
          CoffeeV3SubmissionStore(storage, ownerId: 'owner-b', requireOwner: true);
      expect(store.inspect(), CoffeeV3StoredState.blocked);
      expect(store.load(), isNull);
      await expectLater(
        store.saveDurable(CoffeeV3SubmissionRecord.empty()),
        throwsStateError,
      );
      await expectLater(store.clearDurable(), throwsStateError);
      expect(jsonDecode(storage.getString(CoffeeV3SubmissionStore.key)!)
          .containsKey('ownerId'), isFalse);
      // Even a non-required store with an owner does not adopt it.
      expect(CoffeeV3SubmissionStore(storage, ownerId: 'owner-b').load(), isNull);
    });

    test('cross-owner record is invisible and untouchable', () async {
      final storage = LocalStorage.ephemeral();
      await storage.setString(
          CoffeeV3SubmissionStore.key, jsonEncode(_historicalJson()));
      final b =
          CoffeeV3SubmissionStore(storage, ownerId: 'owner-b', requireOwner: true);
      expect(b.inspect(), CoffeeV3StoredState.blocked);
      expect(b.load(), isNull);
      await expectLater(b.save(CoffeeV3SubmissionRecord.empty()), throwsStateError);
      final a =
          CoffeeV3SubmissionStore(storage, ownerId: 'owner-a', requireOwner: true);
      expect(a.load()?.operationId, _opId);
    });

    test('no owner available: nothing exposed, critical writes refused', () async {
      final storage = LocalStorage.ephemeral();
      await storage.setString(
          CoffeeV3SubmissionStore.key, jsonEncode(_historicalJson()));
      final none = CoffeeV3SubmissionStore(storage, requireOwner: true);
      expect(none.inspect(), CoffeeV3StoredState.blocked);
      expect(none.load(), isNull);
      await expectLater(
        none.saveDurable(CoffeeV3SubmissionRecord.empty()),
        throwsStateError,
      );
    });

    test('a tampered draft path outside coffee_v3_work is never adopted',
        () async {
      final storage = LocalStorage.ephemeral();
      final gallery = await write('DCIM/IMG_0005.jpg');
      final draft = _historicalJson(operationId: null);
      final asset = CoffeeV3PhotoAsset(
        slot: CoffeeV3PhotoSlot.saucer,
        path: gallery.path,
        mimeType: 'image/jpeg',
        // Real size + checksum: ownership is the ONLY reason it is refused.
        sha256: await CoffeeV2Checksum.sha256OfFile(gallery.path),
        sizeBytes: await gallery.length(),
      );
      ((draft['slots'] as Map)['v3_saucer'] as Map)['asset'] = asset.toJson();
      await storage.setString(CoffeeV3SubmissionStore.key, jsonEncode(draft));
      final controller = CoffeeV3SubmissionController(
        flow: ReadingLiveFlow(
          operations: ReadingOperationGateway(send: (_, _, _) async => null),
          acceleration: ReadingAccelerationClient(send: (_, _, _) async => null),
          send: (_, _, _) async => null,
        ),
        stagedImages: ReadingStagedImageGateway((_, _, _) async => null),
        store: CoffeeV3SubmissionStore(storage,
            ownerId: 'owner-a', requireOwner: true),
        creationAllowed: () => true,
      );
      await controller.recoverDraftOrSubmission();
      expect(controller.assetFor(CoffeeV3PhotoSlot.saucer), isNull);
      // Cancel must not delete the gallery original either.
      await controller.cancelDraft();
      expect(await gallery.exists(), isTrue);
    });
  });
}
