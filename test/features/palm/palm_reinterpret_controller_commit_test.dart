/// P0-1 — Palm controller adopts durable reading even when versionAdded=false.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/reading_version/models/reading_version_kind.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_payload.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_service.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:oracly_new/features/palm/controllers/palm_reading_controller.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/services/palm_analysis_port.dart';
import 'package:oracly_new/features/palm/services/palm_experience_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_reading_operation_backend.dart';
import '../../support/false_return_local_storage.dart';
import '../../support/test_path_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late FalseReturnLocalStorage storage;
  late String fixturePath;
  late PalmReadingStore store;
  late ReadingVersionService versions;
  late FakeReadingOperationBackend backend;

  setUp(() async {
    root = await installTestPathProvider('palm-ctrl-commit-');
    SharedPreferences.setMockInitialValues({});
    storage = FalseReturnLocalStorage(await SharedPreferences.getInstance());
    store = PalmReadingStore(storage);
    versions = ReadingVersionService(ReadingVersionStore(storage));
    backend = FakeReadingOperationBackend();
    fixturePath = '${root.path}/palm.jpg';
    await File('test/features/palm/fixtures/palm_sample.jpg').copy(fixturePath);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  PalmReading baseReading({
    String overall = 'old-o',
    String takeaway = 'old-t',
  }) =>
      PalmReading(
        id: 'p-ctrl-1',
        createdAt: DateTime.utc(2026, 1, 1),
        hand: PalmHand.left,
        imagePath: fixturePath,
        overall: overall,
        lifeLine: 'old-l',
        headLine: 'old-h',
        heartLine: 'old-he',
        fateLine: 'old-f',
        takeaway: takeaway,
        symbols: const ['star'],
        themes: const ['calm'],
      );

  Future<PalmReadingController> readyController({
    required PalmAnalysisPort analysis,
    PalmReading? reading,
  }) async {
    final current = reading ?? baseReading();
    await store.save(current);
    final controller = PalmReadingController(
      experience: PalmExperienceService(
        store: store,
        analysis: analysis,
        versions: versions,
        persistImage: ({required readingId, required sourcePath}) async =>
            sourcePath,
      ),
      images: _Images(fixturePath),
      live: fakeImmediateReadingFeatureRunner(backend: backend),
    );
    controller.openSaved(current);
    return controller;
  }

  test(
    'A: metadata save succeeds, version append throws — UI shows NEW reading',
    () async {
      final analysis = _PalmAnalysis(overall: 'new-o', takeaway: 'new-t');
      final controller = await readyController(analysis: analysis);
      final tokenBefore = controller.versionReloadToken;
      final opsBefore = backend.operationCount;

      storage.throwingKeys.add(ReadingVersionStore.key);
      await controller.reinterpret();

      expect(controller.phase, PalmPhase.result);
      expect(controller.errorMessage, isNull);
      expect(controller.reading!.overall, 'new-o');
      expect(controller.reading!.takeaway, 'new-t');
      expect(store.byId('p-ctrl-1')!.overall, 'new-o');
      expect(controller.lastVersionAdded, isFalse);
      expect(controller.versionReloadToken, tokenBefore);
      expect(analysis.calls, 1);
      expect(backend.operationCount, opsBefore + 1);
    },
  );

  test('B: genuine duplicate/no-op — no misleading new version', () async {
    final current = baseReading(overall: 'same-o', takeaway: 'same-t');
    await versions.seedOriginal(
      rootId: current.id,
      kind: ReadingVersionKind.palm,
      data: ReadingVersionPayload.palm(current),
    );
    final analysis = _PalmAnalysis(overall: 'same-o', takeaway: 'same-t');
    final controller =
        await readyController(analysis: analysis, reading: current);
    final tokenBefore = controller.versionReloadToken;

    await controller.reinterpret();

    expect(controller.reading!.overall, 'same-o');
    expect(controller.lastVersionAdded, isFalse);
    expect(controller.versionReloadToken, tokenBefore);
    expect(versions.groupFor(current.id)!.entries, hasLength(1));
    expect(analysis.calls, 1);
  });

  test('C: version append succeeds — reading new + reload token increments',
      () async {
    final current = baseReading();
    await versions.seedOriginal(
      rootId: current.id,
      kind: ReadingVersionKind.palm,
      data: ReadingVersionPayload.palm(current),
    );
    final analysis = _PalmAnalysis(overall: 'rev-o', takeaway: 'rev-t');
    final controller =
        await readyController(analysis: analysis, reading: current);
    final tokenBefore = controller.versionReloadToken;

    await controller.reinterpret();

    expect(controller.reading!.overall, 'rev-o');
    expect(controller.lastVersionAdded, isTrue);
    expect(controller.versionReloadToken, tokenBefore + 1);
    expect(versions.groupFor(current.id)!.entries, hasLength(2));
  });
}

class _Images implements CoffeeImageInputPort {
  _Images(this.path);
  final String path;
  @override
  bool get cameraAvailable => true;
  @override
  bool get galleryAvailable => true;
  @override
  Future<CoffeeImagePick?> pickFromCamera() async =>
      CoffeeImagePick(path: path, mimeType: 'image/jpeg');
  @override
  Future<CoffeeImagePick?> pickFromGallery() async =>
      CoffeeImagePick(path: path, mimeType: 'image/jpeg');
}

class _PalmAnalysis implements PalmAnalysisPort {
  _PalmAnalysis({required this.overall, required this.takeaway});
  final String overall;
  final String takeaway;
  int calls = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<PalmReading> analyze(
    CoffeeImagePick image, {
    required PalmHand hand,
  }) async {
    calls++;
    return PalmReading(
      id: 'p-ctrl-1',
      createdAt: DateTime.utc(2026, 1, 1),
      hand: hand,
      imagePath: image.path,
      overall: overall,
      lifeLine: 'old-l',
      headLine: 'old-h',
      heartLine: 'old-he',
      fateLine: 'old-f',
      takeaway: takeaway,
      symbols: const ['star'],
      themes: const ['calm'],
    );
  }
}
