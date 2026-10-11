/// Coffee V3 (Slice 4, three-photo decision) client contract: rollout flag,
/// slot contract (exactly two cup views + one saucer), local
/// record/store (capture-contract integrity + owner isolation), pairwise
/// validation, exact create bodies (V3 vs unchanged V2/Palm/Soulmate) and
/// account-wipe coverage.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_rollback.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_runtime.dart';
import 'package:oracly_new/core/feature_flags/feature_flag_surface.dart';
import 'package:oracly_new/core/feature_flags/product_feature_flags.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_intention.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_store.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_capture_contract.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_asset.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v3/models/coffee_v3_submission_record.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_creation_gate.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_submission_store.dart';
import 'package:oracly_new/features/coffee/coffee_v3/services/coffee_v3_validation.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_codec.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/coffee_v2_test_support.dart';
import '../../../support/coffee_v3_test_support.dart';
import '../../../support/fake_reading_operation_backend.dart';

CoffeeV3PhotoAsset _asset(CoffeeV3PhotoSlot slot, String sha) =>
    CoffeeV3PhotoAsset(
      slot: slot,
      path: '/tmp/${slot.wireValue}.jpg',
      mimeType: 'image/jpeg',
      sha256: sha,
      sizeBytes: 1000,
    );

CoffeeV3SubmissionRecord _record(
  Map<CoffeeV3PhotoSlot, String?> shas, {
  bool confirmed = true,
  String? operationId,
}) =>
    CoffeeV3SubmissionRecord(
      operationId: operationId,
      intention: 'Aşk ve ilişkilerim hakkında',
      slots: {
        for (final slot in coffeeV3CanonicalSlotOrder)
          slot: shas[slot] == null
              ? const CoffeeV3SlotRecord()
              : CoffeeV3SlotRecord(
                  asset: _asset(slot, shas[slot]!),
                  confirmed: confirmed,
                ),
      },
    );

const _unique = {
  CoffeeV3PhotoSlot.cupViewA: 'a',
  CoffeeV3PhotoSlot.cupViewB: 'b',
  CoffeeV3PhotoSlot.saucer: 'c',
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    OraclyL10n.bind('tr');
    FeatureFlagRuntime.refreshFromRemote(ProductFeatureFlags.defaults());
  });
  tearDown(() {
    OraclyL10n.bind('tr');
    FeatureFlagRuntime.refreshFromRemote(ProductFeatureFlags.defaults());
  });

  group('rollout flag', () {
    test('A coffee_v3_three_view exists, is boolean and defaults FALSE', () {
      final flag = ProductFeatureFlags.coffeeV3ThreeView;
      expect(flag.key, 'coffee_v3_three_view');
      expect(flag.defaultValue, isFalse);
      expect(flag.minAppVersion, isNull);
      expect(ProductFeatureFlags.catalog, contains(flag));
      expect(ProductFeatureFlags.defaults()['coffee_v3_three_view'], isFalse);
      expect(
        FeatureFlagRollback.flag(FeatureFlagSurface.coffeeV3Capture),
        same(flag),
      );
      expect(
        FeatureFlagRollback.useExperimental(FeatureFlagSurface.coffeeV3Capture),
        isFalse,
      );
      expect(CoffeeV3CreationGate.creationAllowed, isFalse);
    });

    test('the retired coffee_v3_four_view key can never enable creation', () {
      expect(ProductFeatureFlags.definitionFor('coffee_v3_four_view'), isNull);
      FeatureFlagRuntime.refreshFromRemote({'coffee_v3_four_view': true});
      expect(CoffeeV3CreationGate.creationAllowed, isFalse);
    });

    test('creation needs flag ON and Turkish UI', () {
      FeatureFlagRuntime.refreshFromRemote({'coffee_v3_three_view': true});
      expect(CoffeeV3CreationGate.creationAllowed, isTrue);
      for (final lang in ['en', 'ru']) {
        OraclyL10n.bind(lang);
        expect(CoffeeV3CreationGate.creationAllowed, isFalse, reason: lang);
      }
      OraclyL10n.bind('tr');
      FeatureFlagRuntime.refreshFromRemote({'coffee_v3_three_view': false});
      expect(CoffeeV3CreationGate.creationAllowed, isFalse);
    });
  });

  group('slot contract', () {
    test('K/L/M exactly three slots (two cup + saucer), wire values and canonical order', () {
      expect(CoffeeV3PhotoSlot.values, hasLength(3));
      expect(coffeeV3CanonicalSlotOrder, [
        CoffeeV3PhotoSlot.cupViewA,
        CoffeeV3PhotoSlot.cupViewB,
        CoffeeV3PhotoSlot.saucer,
      ]);
      expect(
        [for (final s in coffeeV3CanonicalSlotOrder) s.wireValue],
        ['v3_cup_view_a', 'v3_cup_view_b', 'v3_saucer_view'],
      );
      for (final s in CoffeeV3PhotoSlot.values) {
        expect(coffeeV3PhotoSlotFromWire(s.wireValue), s);
      }
      // Retired four-view wire values are never recognized.
      for (final retired in ['v3_cup_handle_far', 'v3_cup_turn_a', 'v3_cup_turn_b', 'v3_saucer']) {
        expect(coffeeV3PhotoSlotFromWire(retired), isNull, reason: retired);
      }
    });

    test('N/O no V2 wire value reused; V3 saucer is never bare saucer', () {
      final v2 = {for (final s in CoffeeV2PhotoSlot.values) s.wireValue};
      for (final s in CoffeeV3PhotoSlot.values) {
        expect(v2.contains(s.wireValue), isFalse);
      }
      expect(CoffeeV3PhotoSlot.saucer.wireValue, 'v3_saucer_view');
      for (final legacy in ['saucer', 'cup_primary', 'cup_secondary']) {
        expect(coffeeV3PhotoSlotFromWire(legacy), isNull);
      }
    });

    test('V2 slot contract is pinned unchanged', () {
      expect(coffeeV2CanonicalSlotOrder, [
        CoffeeV2PhotoSlot.cupPrimary,
        CoffeeV2PhotoSlot.cupSecondary,
        CoffeeV2PhotoSlot.saucer,
      ]);
      expect(
        [for (final s in coffeeV2CanonicalSlotOrder) s.wireValue],
        ['cup_primary', 'cup_secondary', 'saucer'],
      );
    });
  });

  group('local record + store', () {
    test('P persisted record carries captureContract three_view_v3', () {
      final json = _record(_unique).toJson();
      expect(json['captureContract'], 'three_view_v3');
      expect(coffeeV3CaptureContract, 'three_view_v3');
      final back = CoffeeV3SubmissionRecord.fromJson(
        jsonDecode(jsonEncode(json)),
      );
      expect(back.captureContract, 'three_view_v3');
      expect(back.slots[CoffeeV3PhotoSlot.saucer]?.asset?.sha256, 'c');
      // Metadata only — never bytes/base64/tokens.
      final text = jsonEncode(json);
      for (final banned in ['imageBase64', 'bytes', 'token', 'base64']) {
        expect(text.contains(banned), isFalse, reason: banned);
      }
    });

    test('Q missing / unknown / different contract fails closed', () {
      final good = _record(_unique).toJson();
      for (final bad in <Object?>[null, 'four_view_v3', 'four_view_v4', 'three_view_v2', 3]) {
        final json = Map<String, dynamic>.from(good)..['captureContract'] = bad;
        expect(
          () => CoffeeV3SubmissionRecord.fromJson(json),
          throwsFormatException,
          reason: '$bad',
        );
      }
      final missing = Map<String, dynamic>.from(good)..remove('captureContract');
      expect(
        () => CoffeeV3SubmissionRecord.fromJson(missing),
        throwsFormatException,
      );
    });

    test('a stored retired four_view_v3 record is blocked: never adopted, overwritten or removed', () async {
      final storage = LocalStorage.ephemeral();
      final retired = jsonEncode({
        'schemaVersion': 1,
        'captureContract': 'four_view_v3',
        'ownerId': 'o1',
        'operationId': 'op-retired-1',
        'slots': <String, dynamic>{},
      });
      await storage.setString(CoffeeV3SubmissionStore.key, retired);
      final store = CoffeeV3SubmissionStore(storage, ownerId: 'o1');
      expect(store.inspect(), CoffeeV3StoredState.blocked);
      expect(store.load(), isNull);
      await expectLater(store.save(_record(_unique)), throwsStateError);
      expect(storage.getString(CoffeeV3SubmissionStore.key), retired);
    });

    test('an asset filed under the wrong slot is never trusted', () {
      final json = _record(_unique).toJson();
      final slots = json['slots'] as Map<String, dynamic>;
      (slots['v3_cup_view_b'] as Map<String, dynamic>)['asset'] =
          _asset(CoffeeV3PhotoSlot.saucer, 'z').toJson();
      final back = CoffeeV3SubmissionRecord.fromJson(jsonDecode(jsonEncode(json)));
      expect(back.slots[CoffeeV3PhotoSlot.cupViewB]?.asset, isNull);
      expect(back.slots[CoffeeV3PhotoSlot.cupViewB]?.confirmed, isFalse);
    });

    test('separate key: never shares coffee_v2_submission', () async {
      final storage = LocalStorage.ephemeral();
      final v3 = CoffeeV3SubmissionStore(storage, ownerId: 'o1');
      await v3.save(_record(_unique));
      expect(CoffeeV3SubmissionStore.key, 'coffee_v3_submission');
      expect(storage.getString('coffee_v3_submission'), isNotNull);
      expect(storage.getString('coffee_v2_submission'), isNull);
      expect(CoffeeV2SubmissionStore(storage, ownerId: 'o1').load(), isNull);
    });

    test('unknown stored contract: inspect=blocked, load=null, never overwritten',
        () async {
      final storage = LocalStorage.ephemeral();
      final json = _record(_unique).toJson()..['captureContract'] = 'future_v9';
      await storage.setString(CoffeeV3SubmissionStore.key, jsonEncode(json));
      final store = CoffeeV3SubmissionStore(storage, ownerId: 'o1');
      expect(store.inspect(), CoffeeV3StoredState.blocked);
      expect(store.load(), isNull);
      await expectLater(store.save(_record(_unique)), throwsStateError);
      expect(jsonDecode(storage.getString(CoffeeV3SubmissionStore.key)!)
          ['captureContract'], 'future_v9');
    });

    test('owner isolation: A\'s record invisible / untouchable for B', () async {
      final storage = LocalStorage.ephemeral();
      final a = CoffeeV3SubmissionStore(storage, ownerId: 'owner-a',
          requireOwner: true);
      await a.saveDurable(_record(_unique, operationId: '0' * 32));
      expect(a.inspect(), CoffeeV3StoredState.active);
      final b = CoffeeV3SubmissionStore(storage, ownerId: 'owner-b',
          requireOwner: true);
      expect(b.load(), isNull);
      expect(b.inspect(), CoffeeV3StoredState.blocked);
      await expectLater(b.save(_record(_unique)), throwsStateError);
      await expectLater(b.clearDurable(), throwsStateError);
      expect(a.load()?.operationId, '0' * 32);
      expect(a.load()?.ownerId, 'owner-a');
      // No owner available: nothing exposed, critical writes refused.
      final none = CoffeeV3SubmissionStore(storage, requireOwner: true);
      expect(none.load(), isNull);
      expect(none.inspect(), CoffeeV3StoredState.blocked);
      await expectLater(none.saveDurable(_record(_unique)), throwsStateError);
    });

    test('account wipe clears both V3 keys', () async {
      SharedPreferences.setMockInitialValues({
        'coffee_v3_submission': '{}',
        'coffee_v3_acknowledged_operation': '{}',
      });
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final root = await Directory.systemTemp.createTemp('coffee_v3_wipe_');
      addTearDown(() => root.delete(recursive: true));
      installCoffeeV3SupportRoot(root.path);
      await UserLocalDataWipe.run(storage, secureStorage: InMemorySecureStorage());
      expect(storage.getString('coffee_v3_submission'), isNull);
      expect(storage.getString('coffee_v3_acknowledged_operation'), isNull);
    });
  });

  group('validation', () {
    test('R 0-2 confirmed blocked; S three unique confirmed valid', () {
      final slots = coffeeV3CanonicalSlotOrder;
      for (var n = 0; n < 3; n++) {
        final shas = {
          for (var i = 0; i < 3; i++) slots[i]: i < n ? _unique[slots[i]] : null,
        };
        expect(CoffeeV3Validation.evaluate(_record(shas)),
            CoffeeV3ValidationIssue.incomplete, reason: '$n');
      }
      expect(CoffeeV3Validation.evaluate(_record(_unique, confirmed: false)),
          CoffeeV3ValidationIssue.incomplete);
      expect(CoffeeV3Validation.evaluate(_record(_unique)), isNull);
    });

    test('T every pairwise duplicate blocks (all 3 pairs: cup/cup, cup/saucer)', () {
      final slots = coffeeV3CanonicalSlotOrder;
      var pairs = 0;
      for (var i = 0; i < 3; i++) {
        for (var j = i + 1; j < 3; j++) {
          final shas = Map<CoffeeV3PhotoSlot, String?>.from(_unique)
            ..[slots[j]] = _unique[slots[i]];
          expect(CoffeeV3Validation.evaluate(_record(shas)),
              CoffeeV3ValidationIssue.duplicate, reason: '$i-$j');
          final candidate = _asset(slots[j], _unique[slots[i]]!);
          expect(
            CoffeeV3Validation.duplicateOf(candidate, {
              for (final s in slots) s: _asset(s, _unique[s]!),
            }),
            slots[i],
          );
          pairs++;
        }
      }
      expect(pairs, 3);
    });
  });

  group('create body', () {
    const codec = ReadingOperationCodec();

    test('Y exact V3 body', () {
      expect(
        codec.createBody(
          readingType: ReadingType.coffee,
          sourceRequestId: 'coffee-v3-123456',
          language: 'tr',
          intention: 'Aşk ve ilişkilerim hakkında',
          coffeeInputContract: coffeeV2InputContract,
          coffeeCaptureContract: coffeeV3CaptureContract,
        ),
        {
          'readingType': 'coffee',
          'sourceRequestId': 'coffee-v3-123456',
          'language': 'tr',
          'intention': 'Aşk ve ilişkilerim hakkında',
          'coffeeInputContract': 'trusted_intention_v1',
          'coffeeCaptureContract': 'three_view_v3',
        },
      );
    });

    test('AB null capture contract omits the field (byte-for-map identical)',
        () {
      final body = codec.createBody(
        readingType: ReadingType.coffee,
        sourceRequestId: 'coffee-v2-1',
        intention: 'x',
        coffeeInputContract: coffeeV2InputContract,
      );
      expect(body, {
        'readingType': 'coffee',
        'sourceRequestId': 'coffee-v2-1',
        'language': 'tr',
        'intention': 'x',
        'coffeeInputContract': 'trusted_intention_v1',
      });
      expect(body.containsKey('coffeeCaptureContract'), isFalse);
    });

    test('AA Palm / Soulmate bodies unchanged (capture contract never sent)',
        () {
      expect(
        codec.createBody(
          readingType: ReadingType.palm,
          sourceRequestId: 'palm-1234',
          coffeeCaptureContract: coffeeV3CaptureContract,
        ),
        {'readingType': 'palm', 'sourceRequestId': 'palm-1234', 'language': 'tr'},
      );
      expect(
        codec.createBody(
          readingType: ReadingType.soulmate,
          sourceRequestId: 'soul-1234',
          executionMode: 'durable',
          coffeeCaptureContract: coffeeV3CaptureContract,
        ),
        {
          'readingType': 'soulmate',
          'sourceRequestId': 'soul-1234',
          'language': 'tr',
          'executionMode': 'durable',
        },
      );
    });

    test('gateway + ReadingLiveFlow forward the optional field only when set',
        () async {
      final transport = CoffeeV3TestTransport(FakeReadingOperationBackend());
      final flow = ReadingLiveFlow(
        operations: ReadingOperationGateway(send: transport.send),
        acceleration: ReadingAccelerationClient(send: transport.send),
        send: transport.send,
      );
      await flow.begin(
        readingType: ReadingType.coffee,
        sourceRequestId: 'coffee-v3-1111',
        intention: 'x',
        coffeeInputContract: coffeeV2InputContract,
        coffeeCaptureContract: coffeeV3CaptureContract,
      );
      await flow.begin(readingType: ReadingType.palm, sourceRequestId: 'p-12345678');
      expect(transport.creates[0].body?['coffeeCaptureContract'], 'three_view_v3');
      expect(transport.creates[1].body?.containsKey('coffeeCaptureContract'),
          isFalse);
    });

    test('Z the real Coffee V2 create body is exact and has NO capture contract',
        () async {
      final temp = await Directory.systemTemp.createTemp('coffee_v3_z_');
      addTearDown(() => temp.delete(recursive: true));
      final transport = CoffeeV3TestTransport(FakeReadingOperationBackend());
      final flow = ReadingLiveFlow(
        operations: ReadingOperationGateway(send: transport.send),
        acceleration: ReadingAccelerationClient(send: transport.send),
        send: transport.send,
      );
      final v2 = CoffeeV2SubmissionController(
        flow: flow,
        stagedImages: ReadingStagedImageGateway(transport.send),
        store: CoffeeV2SubmissionStore(LocalStorage.ephemeral(), ownerId: 'o'),
        normalizer: ScriptedCoffeeV2Normalizer((s) async => s),
        messages: coffeeV2TestMessages,
      );
      var size = 9001;
      for (final slot in coffeeV2CanonicalSlotOrder) {
        final file = File('${temp.path}/${slot.wireValue}.jpg');
        await file.writeAsBytes(plainJpegBytes(totalSize: size += 100));
        await v2.setSlot(slot, CoffeeImagePick(path: file.path));
        await v2.confirmSlot(slot);
      }
      await v2.setIntention('Aşk ve ilişkilerim hakkında');
      await v2.beginSubmission('coffee-v2-777777');
      expect(transport.creates.single.body, {
        'readingType': 'coffee',
        'sourceRequestId': 'coffee-v2-777777',
        'language': 'tr',
        'intention': 'Aşk ve ilişkilerim hakkında',
        'coffeeInputContract': 'trusted_intention_v1',
      });
      expect(transport.stagedSlots, ['cup_primary', 'cup_secondary', 'saucer']);
      expect(
        transport.calls.any((c) => c.body?.containsKey('coffeeCaptureContract') ?? false),
        isFalse,
      );
    });
  });
}
