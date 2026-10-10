/// Slice 4B — Coffee V2 normalized working-file lifecycle + privacy.
/// Rejected candidates and replaced photos no longer accumulate in
/// `{support}/coffee_v2_work`; only app-owned `coffee_v2_work_*` copies are
/// ever deleted (never camera/gallery originals, V3, Palm, archive or
/// tampered metadata paths); ACTIVE sessions keep their bound files; the
/// shared account-boundary wipe strictly purges V2 working copies before
/// clearing V2 metadata and reports honestly when it cannot.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/features/ai/production/transport/image_normalizer.dart';
import 'package:oracly_new/features/coffee/coffee_v2/controllers/coffee_v2_flow_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_flow_stage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_intention.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_stage_state.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_normalizer.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_store.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_work_files.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/openai_coffee_analysis.dart';
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
import '../../../support/false_return_local_storage.dart';
import '../../../support/fake_reading_operation_backend.dart';
import '../../../support/test_path_provider.dart';

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

// SYNTHETIC (never product copy).
const _overall = '  Fincanda bir konu ön plana çıkabilir;  kesin olacak gibi değil.\n';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory work;
  late Directory sources; // camera / gallery originals live here
  late LocalStorage storage;
  late FakeReadingOperationBackend backend;
  late RecordingStagedTransport transport;
  final controllers = <CoffeeV2FlowController>[];
  var size = 9000;
  var counter = 0;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('coffee_v2_4b_');
    PathProviderPlatform.instance = TestPathProvider(root.path);
    work = Directory('${root.path}/${CoffeeV2WorkFiles.dirName}');
    sources = Directory('${root.path}/DCIM')..createSync(recursive: true);
    storage = LocalStorage.ephemeral();
    backend = FakeReadingOperationBackend(immediatelyEligible: false);
    transport = RecordingStagedTransport(backend);
  });

  tearDown(() async {
    for (final c in controllers) {
      c.dispose();
    }
    controllers.clear();
    if (await root.exists()) await root.delete(recursive: true);
  });

  /// Behaves like `DefaultCoffeeV2Normalizer`: writes an app-owned COPY of
  /// the source into `{support}/coffee_v2_work/coffee_v2_work_{n}.jpg`.
  CoffeeV2Normalizer ownedNormalizer() => ScriptedCoffeeV2Normalizer((s) async {
        if (s.path.contains('broken')) {
          throw const ImageNormalizeException(
            'normalize_failed',
            kind: ImageNormalizeKind.failed,
          );
        }
        work.createSync(recursive: true);
        final out =
            '${work.path}/${CoffeeV2WorkFiles.filePrefix}${DateTime.now().microsecondsSinceEpoch}_${counter++}.jpg';
        if (s.path.contains('huge')) {
          // Normalized output over the 8 MiB V2 ceiling.
          await File(out).writeAsBytes(List.filled(8 * 1024 * 1024 + 1, 0));
        } else {
          await File(s.path).copy(out);
        }
        return CoffeeImagePick(path: out, mimeType: 'image/jpeg');
      });

  CoffeeV2SubmissionController submission({
    LocalStorage? using,
    CoffeeV2Normalizer? normalizer,
  }) {
    final flow = ReadingLiveFlow(
      operations: ReadingOperationGateway(send: transport.send),
      acceleration: ReadingAccelerationClient(send: transport.send),
      send: transport.send,
    );
    return CoffeeV2SubmissionController(
      flow: flow,
      stagedImages: ReadingStagedImageGateway(transport.send),
      store: CoffeeV2SubmissionStore(using ?? storage,
          ownerId: 'owner-v2', requireOwner: true),
      normalizer: normalizer ?? ownedNormalizer(),
      messages: coffeeV2TestMessages,
    );
  }

  late CoffeeReadingStore readings;
  CoffeeV2FlowController build({LocalStorage? using}) {
    readings = CoffeeReadingStore(using ?? storage);
    final sub = submission(using: using);
    final c = CoffeeV2FlowController(
      submission: sub,
      flow: sub.flow,
      experience: CoffeeExperienceService(
        store: readings,
        analysis: OpenAiCoffeeAnalysis(ai: NoProviderAi()),
      ),
    );
    controllers.add(c);
    return c;
  }

  Future<String> original(String name, {int? bytes}) async {
    final f = File('${sources.path}/$name.jpg');
    await f.writeAsBytes(plainJpegBytes(totalSize: bytes ?? (size += 53)));
    return f.path;
  }

  List<String> workFiles() => work.existsSync()
      ? (work.listSync().whereType<File>().map((f) => f.path).toList()..sort())
      : <String>[];

  Future<Map<CoffeeV2PhotoSlot, int>> confirmThree(CoffeeV2FlowController c) async {
    await c.boot();
    c.dismissIntro();
    final sizes = <CoffeeV2PhotoSlot, int>{};
    for (final slot in coffeeV2CanonicalSlotOrder) {
      sizes[slot] = size += 211;
      c.setPreviewCandidate(
        slot,
        CoffeeImagePick(path: await original('orig_${slot.name}', bytes: sizes[slot])),
      );
      expect(await c.confirmCandidate(), CoffeeV2ConfirmOutcome.committedAdvance);
    }
    expect(c.stage, CoffeeV2FlowStage.finalReview);
    return sizes;
  }

  Future<CoffeeV2ConfirmOutcome> replace(
    CoffeeV2FlowController c,
    CoffeeV2PhotoSlot slot,
    String path,
  ) async {
    c.beginReplacing(slot);
    c.setPreviewCandidate(slot, CoffeeImagePick(path: path));
    return c.confirmCandidate();
  }

  Future<void> waitFor(bool Function() condition, {int seconds = 6}) async {
    final deadline = DateTime.now().add(Duration(seconds: seconds));
    while (!condition()) {
      if (DateTime.now().isAfter(deadline)) fail('condition not reached');
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
  }

  group('candidate + replacement cleanup', () {
    test('1/2 rejected duplicate: its owned copy deleted, previous photo kept',
        () async {
      final c = build();
      final sizes = await confirmThree(c);
      final before = c.record.slots[CoffeeV2PhotoSlot.saucer]!.asset!;
      final filesBefore = workFiles();
      expect(filesBefore, hasLength(3));

      final dupSource = await original('dup',
          bytes: sizes[CoffeeV2PhotoSlot.cupPrimary]);
      expect(await replace(c, CoffeeV2PhotoSlot.saucer, dupSource),
          CoffeeV2ConfirmOutcome.duplicate);
      expect(workFiles(), filesBefore); // candidate copy released
      expect(c.record.slots[CoffeeV2PhotoSlot.saucer]!.asset, before);
      expect(c.record.slots[CoffeeV2PhotoSlot.saucer]!.confirmed, isTrue);
      expect(await File(before.path).exists(), isTrue);
      expect(await File(dupSource).exists(), isTrue); // original untouched
    });

    test('3 invalid / oversized replacement keeps previous photo and file',
        () async {
      final c = build();
      await confirmThree(c);
      final before = c.record.slots[CoffeeV2PhotoSlot.cupSecondary]!.asset!;
      final filesBefore = workFiles();
      for (final name in ['broken', 'huge']) {
        expect(
          await replace(c, CoffeeV2PhotoSlot.cupSecondary, await original(name)),
          CoffeeV2ConfirmOutcome.invalidPhoto,
          reason: name,
        );
        expect(c.record.slots[CoffeeV2PhotoSlot.cupSecondary]!.asset, before);
        expect(await File(before.path).exists(), isTrue);
        expect(workFiles(), filesBefore, reason: name); // no orphan left
      }
    });

    test('4 successful replacement deletes the old copy only after commit',
        () async {
      final c = build();
      await confirmThree(c);
      final old = c.record.slots[CoffeeV2PhotoSlot.cupPrimary]!.asset!;
      final source = await original('fresh');
      expect(await replace(c, CoffeeV2PhotoSlot.cupPrimary, source),
          CoffeeV2ConfirmOutcome.committedReturnToReview);
      final fresh = c.record.slots[CoffeeV2PhotoSlot.cupPrimary]!.asset!;
      expect(fresh.path, isNot(old.path));
      expect(await File(old.path).exists(), isFalse);
      expect(await File(fresh.path).exists(), isTrue);
      expect(workFiles(), hasLength(3));
      expect(await File(source).exists(), isTrue);
      // Persisted state matches.
      final persisted =
          CoffeeV2SubmissionStore(storage, ownerId: 'owner-v2').load()!;
      expect(persisted.slots[CoffeeV2PhotoSlot.cupPrimary]!.asset, fresh);
      expect(persisted.slots[CoffeeV2PhotoSlot.cupPrimary]!.confirmed, isTrue);
    });

    test('5 failed durable commit keeps the old confirmed photo and file',
        () async {
      SharedPreferences.setMockInitialValues({});
      final failing = FalseReturnLocalStorage(await SharedPreferences.getInstance());
      final c = build(using: failing);
      await confirmThree(c);
      final old = c.record.slots[CoffeeV2PhotoSlot.saucer]!.asset!;
      final filesBefore = workFiles();
      failing.falseReturnKeys.add('coffee_v2_submission');
      expect(await replace(c, CoffeeV2PhotoSlot.saucer, await original('late')),
          CoffeeV2ConfirmOutcome.invalidPhoto);
      expect(c.record.slots[CoffeeV2PhotoSlot.saucer]!.asset, old);
      expect(await File(old.path).exists(), isTrue);
      expect(workFiles(), filesBefore); // candidate copy released
      failing.falseReturnKeys.clear();
      final persisted =
          CoffeeV2SubmissionStore(failing, ownerId: 'owner-v2').load()!;
      expect(persisted.slots[CoffeeV2PhotoSlot.saucer]!.asset, old);
    });

    test('6 a working copy still referenced by another slot is never deleted',
        () async {
      work.createSync(recursive: true);
      final shared = File('${work.path}/${CoffeeV2WorkFiles.filePrefix}shared.jpg')
        ..writeAsBytesSync(plainJpegBytes(totalSize: 7777));
      var next = shared.path;
      final sub = submission(
        normalizer: ScriptedCoffeeV2Normalizer(
          (_) async => CoffeeImagePick(path: next, mimeType: 'image/jpeg'),
        ),
      );
      final pick = CoffeeImagePick(path: await original('x'));
      await sub.setSlot(CoffeeV2PhotoSlot.cupPrimary, pick);
      await sub.setSlot(CoffeeV2PhotoSlot.cupSecondary, pick);
      final a = File('${work.path}/${CoffeeV2WorkFiles.filePrefix}a.jpg')
        ..writeAsBytesSync(plainJpegBytes(totalSize: 7001));
      next = a.path;
      await sub.setSlot(CoffeeV2PhotoSlot.cupPrimary, pick);
      expect(await shared.exists(), isTrue); // cupSecondary still uses it
      final b = File('${work.path}/${CoffeeV2WorkFiles.filePrefix}b.jpg')
        ..writeAsBytesSync(plainJpegBytes(totalSize: 7002));
      next = b.path;
      await sub.setSlot(CoffeeV2PhotoSlot.cupSecondary, pick);
      expect(await shared.exists(), isFalse); // now unreferenced → released
      expect(await a.exists(), isTrue);
    });

    test('7 gallery / camera originals are never deleted, even if referenced',
        () async {
      // An older client / scripted normalizer that kept the ORIGINAL path.
      final sub = submission(normalizer: ScriptedCoffeeV2Normalizer((s) async => s));
      final gallery = await original('gallery_original');
      final camera = await original('camera_original');
      await sub.setSlot(CoffeeV2PhotoSlot.cupPrimary, CoffeeImagePick(path: gallery));
      await sub.setSlot(CoffeeV2PhotoSlot.cupPrimary, CoffeeImagePick(path: camera));
      expect(await File(gallery).exists(), isTrue); // replaced, not deleted
      await sub.clearSlot(CoffeeV2PhotoSlot.cupPrimary);
      await sub.setSlot(CoffeeV2PhotoSlot.saucer, CoffeeImagePick(path: gallery));
      await sub.cancelDraft();
      expect(await File(gallery).exists(), isTrue);
      expect(await File(camera).exists(), isTrue);
    });
  });

  group('ownership boundary', () {
    test('8/9 only coffee_v2_work_* inside coffee_v2_work is owned', () async {
      Future<File> at(String rel) async {
        final f = File('${root.path}/$rel');
        await f.parent.create(recursive: true);
        await f.writeAsBytes([1, 2, 3]);
        return f;
      }

      final owned = await at('coffee_v2_work/coffee_v2_work_1.jpg');
      expect(await CoffeeV2WorkFiles.classify(owned.path), ArchivePathKind.owned);
      for (final rel in [
        'coffee_v3_work/coffee_v3_work_1.jpg',
        'coffee_v3_work/coffee_v2_work_1.jpg', // right prefix, wrong dir
        'palm_images/palm_1.jpg',
        'coffee_images/r1_1.jpg',
        'DCIM/IMG_1.jpg',
        'coffee_v2_work/other.jpg',
        'coffee_v2_work_9.jpg', // prefix outside the dir
      ]) {
        final f = await at(rel);
        expect(await CoffeeV2WorkFiles.classify(f.path), ArchivePathKind.notOwned,
            reason: rel);
        expect(await CoffeeV2WorkFiles.deleteIfOwnedStrict(f.path), isTrue);
        expect(await f.exists(), isTrue, reason: rel);
      }
      final traversal =
          '${root.path}/coffee_v2_work/../coffee_v3_work/coffee_v2_work_1.jpg';
      expect(await CoffeeV2WorkFiles.classify(traversal), ArchivePathKind.notOwned);
      expect(await CoffeeV2WorkFiles.classify(null), ArchivePathKind.notOwned);

      // V2 purge leaves V3 / Palm / archive / originals / sub-dirs alone.
      final nested = await at('coffee_v2_work/coffee_v2_work_dir/inner.jpg');
      final v3 = File('${root.path}/coffee_v3_work/coffee_v3_work_1.jpg');
      expect(await CoffeeV2WorkFiles.purgeStrict(), isTrue);
      expect(await owned.exists(), isFalse);
      expect(await nested.exists(), isTrue);
      expect(await v3.exists(), isTrue);
      expect(await File('${root.path}/palm_images/palm_1.jpg').exists(), isTrue);
      expect(await File('${root.path}/coffee_images/r1_1.jpg').exists(), isTrue);
      expect(await File('${root.path}/DCIM/IMG_1.jpg').exists(), isTrue);
    });

    test('unknown ownership (path_provider failure) never deletes', () async {
      work.createSync(recursive: true);
      final owned = File('${work.path}/${CoffeeV2WorkFiles.filePrefix}u.jpg')
        ..writeAsBytesSync([1]);
      PathProviderPlatform.instance = _BrokenPathProvider();
      expect(await CoffeeV2WorkFiles.classify(owned.path), ArchivePathKind.unknown);
      expect(await CoffeeV2WorkFiles.deleteIfOwnedStrict(owned.path), isFalse);
      expect(await CoffeeV2WorkFiles.purgeStrict(), isFalse);
      expect(await owned.exists(), isTrue);
    });
  });

  group('session lifecycle', () {
    test('10 draft cancel deletes owned V2 copies only', () async {
      final c = build();
      await confirmThree(c);
      expect(workFiles(), hasLength(3));
      await c.submission!.cancelDraft();
      expect(workFiles(), isEmpty);
      expect(sources.listSync(), hasLength(3)); // originals intact
    });

    test('12/13 ACTIVE restart keeps bound files; retry stages the SAME op',
        () async {
      transport.failSlotsOnce.add('saucer');
      final c = build();
      await confirmThree(c);
      await c.selectIntention(CoffeeV2IntentionChoice.general);
      await c.beginSubmission();
      expect(c.record.isActive, isTrue);
      final opId = c.record.operationId;
      final bound = workFiles();
      expect(bound, hasLength(3));
      c.dispose();
      controllers.remove(c);

      final restarted = build();
      await restarted.boot(); // resumes staging automatically
      await waitFor(() => !restarted.stagingInFlight &&
          restarted.record.slots[CoffeeV2PhotoSlot.saucer]!.stageState ==
              CoffeeV2StageState.staged);
      expect(restarted.record.operationId, opId);
      expect(backend.operationCount, 1);
      expect(workFiles(), bound); // still needed until a terminal result
    });

    test('11 completed result releases files; result identity + history kept',
        () async {
      final c = build();
      await confirmThree(c);
      await c.selectIntention(CoffeeV2IntentionChoice.general);
      await c.beginSubmission();
      final opId = c.record.operationId!;
      backend.completeServerSide(opId,
          resultId: 'coffee-v2-r1', result: m2PublicV1Result(_overall));
      await waitFor(() => c.record.resultPendingAcknowledgement);
      await waitFor(() => workFiles().isEmpty);
      expect(c.record.operationId, opId);
      expect(c.record.resultId, 'coffee-v2-r1');
      expect(readings.byId('coffee-v2-r1')?.overall, _overall); // history
      expect(sources.listSync(), hasLength(3));

      c.dispose();
      controllers.remove(c);
      final restarted = build();
      await restarted.boot();
      expect(restarted.reading?.id, 'coffee-v2-r1');
      expect(restarted.reading?.overall, _overall);
    });
  });

  group('account-boundary wipe', () {
    Future<LocalStorage> seeded() async {
      SharedPreferences.setMockInitialValues({
        'coffee_v2_submission': '{"slots":{}}',
        'coffee_v2_acknowledged_operation': '{}',
      });
      return LocalStorage(await SharedPreferences.getInstance());
    }

    test('14 removes referenced AND orphaned V2 copies, then V2 metadata',
        () async {
      final wipeStorage = await seeded();
      work.createSync(recursive: true);
      final orphan = File('${work.path}/${CoffeeV2WorkFiles.filePrefix}orphan.jpg')
        ..writeAsBytesSync([1]);
      final referenced = File('${work.path}/${CoffeeV2WorkFiles.filePrefix}ref.jpg')
        ..writeAsBytesSync([2]);
      final v3 = File('${root.path}/coffee_v3_work/coffee_v3_work_keep.jpg')
        ..createSync(recursive: true);
      final gallery = File(await original('kept'));
      final result = await UserLocalDataWipe.run(
        wipeStorage,
        secureStorage: InMemorySecureStorage(),
      );
      expect(result.failedOperations, isNot(contains('coffee_v2_work_images')));
      expect(result.failedOperations, isNot(contains('coffee_v2_submission')));
      expect(await orphan.exists(), isFalse);
      expect(await referenced.exists(), isFalse);
      expect(await gallery.exists(), isTrue);
      // V3 copies are reclaimed by the separate V3 step, never by V2's.
      expect(await v3.exists(), isFalse);
      expect(wipeStorage.getString('coffee_v2_submission'), isNull);
      expect(wipeStorage.getString('coffee_v2_acknowledged_operation'), isNull);
    });

    test('15/16 failed physical cleanup → incomplete + metadata kept; retry ok',
        () async {
      final wipeStorage = await seeded();
      work.createSync(recursive: true);
      final file = File('${work.path}/${CoffeeV2WorkFiles.filePrefix}stuck.jpg')
        ..writeAsBytesSync([1]);
      PathProviderPlatform.instance = _BrokenPathProvider();
      final failed = await UserLocalDataWipe.run(
        wipeStorage,
        secureStorage: InMemorySecureStorage(),
      );
      expect(failed.isComplete, isFalse);
      expect(failed.failedOperations, contains('coffee_v2_work_images'));
      expect(failed.failedOperations, contains('coffee_v2_submission'));
      expect(wipeStorage.getString('coffee_v2_submission'), isNotNull);
      expect(await file.exists(), isTrue);

      PathProviderPlatform.instance = TestPathProvider(root.path);
      final retry = await UserLocalDataWipe.run(
        wipeStorage,
        secureStorage: InMemorySecureStorage(),
      );
      expect(retry.failedOperations, isNot(contains('coffee_v2_work_images')));
      expect(await file.exists(), isFalse);
      expect(wipeStorage.getString('coffee_v2_submission'), isNull);
    });

    test('15 (filesystem) a locked file makes the purge incomplete', () async {
      work.createSync(recursive: true);
      final locked = File('${work.path}/${CoffeeV2WorkFiles.filePrefix}lock.jpg')
        ..writeAsBytesSync([1]);
      final handle = await locked.open(mode: FileMode.append);
      final first = await CoffeeV2WorkFiles.purgeStrict();
      if (Platform.isWindows) {
        expect(first, isFalse);
        expect(await locked.exists(), isTrue);
      }
      await handle.close();
      expect(await CoffeeV2WorkFiles.purgeStrict(), isTrue);
      expect(await locked.exists(), isFalse);
    });

    test('17 missing dir / missing files / repeated cleanup are safe', () async {
      expect(work.existsSync(), isFalse);
      expect(await CoffeeV2WorkFiles.purgeStrict(), isTrue);
      expect(work.existsSync(), isFalse); // never created by cleanup
      final missing = '${work.path}/${CoffeeV2WorkFiles.filePrefix}gone.jpg';
      expect(await CoffeeV2WorkFiles.deleteIfOwnedStrict(missing), isTrue);
      expect(await CoffeeV2WorkFiles.deleteIfOwnedStrict(missing), isTrue);
      work.createSync(recursive: true);
      File('${work.path}/${CoffeeV2WorkFiles.filePrefix}x.jpg').writeAsBytesSync([1]);
      expect(await CoffeeV2WorkFiles.purgeStrict(), isTrue);
      expect(await CoffeeV2WorkFiles.purgeStrict(), isTrue);
    });
  });
}
