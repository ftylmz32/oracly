/// Coffee V2 client foundation — Phase 2C1 §30 "REQUIRED TESTS — MEMORY
/// DISCIPLINE" (AC-AG). Proves architecture-level sequential byte
/// ownership — never device RSS.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/coffee_v2/models/coffee_v2_photo_slot.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_controller.dart';
import 'package:oracly_new/features/coffee/coffee_v2/services/coffee_v2_submission_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import '../../../support/coffee_v2_test_support.dart';
import '../../../support/fake_reading_operation_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late FakeReadingOperationBackend backend;
  late List<String> chronology;
  late RecordingStagedTransport transport;
  late RecordingByteLoader byteLoader;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('coffee_v2_memory_test_');
    PathProviderPlatform.instance = FakePathProvider(temp.path);
    backend = FakeReadingOperationBackend();
    chronology = [];
    transport = RecordingStagedTransport(backend, chronology: chronology);
    byteLoader = RecordingByteLoader(chronology);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  CoffeeV2SubmissionController buildController() {
    final operations = ReadingOperationGateway(send: transport.send);
    return CoffeeV2SubmissionController(
      flow: ReadingLiveFlow(
        operations: operations,
        acceleration: ReadingAccelerationClient(send: transport.send),
        send: transport.send,
      ),
      stagedImages: ReadingStagedImageGateway(transport.send),
      store: CoffeeV2SubmissionStore(LocalStorage.ephemeral()),
      byteLoader: byteLoader,
      messages: coffeeV2TestMessages,
    );
  }

  Future<String> writeJpeg(String name, {int totalSize = 9 * 1024}) async {
    final path = '${temp.path}/$name';
    await File(path).writeAsBytes(plainJpegBytes(totalSize: totalSize));
    return path;
  }

  Future<CoffeeV2SubmissionController> readyToSubmit() async {
    final controller = buildController();
    final primary = await writeJpeg('primary.jpg', totalSize: 9001);
    final secondary = await writeJpeg('secondary.jpg', totalSize: 9101);
    final saucer = await writeJpeg('saucer.jpg', totalSize: 9201);
    for (final entry in {
      CoffeeV2PhotoSlot.cupPrimary: primary,
      CoffeeV2PhotoSlot.cupSecondary: secondary,
      CoffeeV2PhotoSlot.saucer: saucer,
    }.entries) {
      await controller.setSlot(entry.key, CoffeeImagePick(path: entry.value));
      await controller.confirmSlot(entry.key);
    }
    return controller;
  }

  test('AC — before staging begins, no image bytes are loaded', () async {
    await readyToSubmit();
    expect(chronology.where((e) => e.startsWith('load:')), isEmpty);
  });

  test(
    'AD/AE/AF — strict load-then-stage-then-next-load ordering per slot',
    () async {
      final controller = await readyToSubmit();
      await controller.beginSubmission('src-mem');

      // Loader/stage entries record the normalized working-file basename
      // (not the picked-file path) so each ordering assertion is
      // unambiguous per slot.
      String basenameFor(CoffeeV2PhotoSlot slot) =>
          controller.assetFor(slot)!.path.split(Platform.pathSeparator).last;

      int loadIndex(CoffeeV2PhotoSlot slot) => chronology.indexWhere(
            (e) => e.startsWith('load:') && e.contains(basenameFor(slot)),
          );
      int stageIndex(CoffeeV2PhotoSlot slot) =>
          chronology.indexOf('stage:${slot.wireValue}');

      final loadPrimaryIndex = loadIndex(CoffeeV2PhotoSlot.cupPrimary);
      final stagePrimaryIndex = stageIndex(CoffeeV2PhotoSlot.cupPrimary);
      final loadSecondaryIndex = loadIndex(CoffeeV2PhotoSlot.cupSecondary);
      final stageSecondaryIndex = stageIndex(CoffeeV2PhotoSlot.cupSecondary);
      final loadSaucerIndex = loadIndex(CoffeeV2PhotoSlot.saucer);

      expect(loadPrimaryIndex, greaterThanOrEqualTo(0));
      // AD: while cup_primary is being staged, only cup_primary's bytes
      // have been requested so far.
      expect(loadPrimaryIndex, lessThan(stagePrimaryIndex));
      // AE: cup_secondary bytes are not requested until cup_primary's
      // stage future has completed.
      expect(loadSecondaryIndex, greaterThan(stagePrimaryIndex));
      expect(loadSecondaryIndex, lessThan(stageSecondaryIndex));
      // AF: saucer bytes are not requested until cup_secondary completes.
      expect(loadSaucerIndex, greaterThan(stageSecondaryIndex));
    },
  );

  test(
    'AG — no persistent three-image byte cache in the controller/coordinator source',
    () {
      final source = File(
        'lib/features/coffee/coffee_v2/services/coffee_v2_submission_controller.dart',
      ).readAsStringSync();
      // Structural guard against the exact anti-patterns the spec forbids:
      // holding all three images' bytes at once as fields/locals.
      expect(source.contains('List<Uint8List>'), isFalse);
      expect(source.contains('List<List<int>>'), isFalse);
      expect(RegExp(r'Map<[^>]*,\s*(Uint8List|List<int>)>').hasMatch(source), isFalse);
      // The only byte-holding local is the single per-iteration `bytes`
      // variable inside the sequential staging loop.
      expect(RegExp(r'final bytes = await byteLoader\.loadBytes').hasMatch(source), isTrue);
    },
  );
}
