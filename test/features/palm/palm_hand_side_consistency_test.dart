/// Palm hand correction: the chosen hand stays that hand end to end —
/// selection, staged request, analysis, saved reading, reopen, reinterpret.
/// Fake backend and fake analysis only; no provider call, no AI quality claim.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
import 'package:oracly_new/features/reading_operation/services/reading_acceleration_client.dart';
import 'package:oracly_new/features/reading_operation/services/reading_feature_runner.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_input_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_staged_image_gateway.dart';
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
  late FakeReadingOperationBackend backend;
  late List<String?> stagedHands;
  late _PalmAnalysis analysis;

  setUp(() async {
    root = await installTestPathProvider('palm-hand-side-');
    SharedPreferences.setMockInitialValues({});
    storage = FalseReturnLocalStorage(await SharedPreferences.getInstance());
    store = PalmReadingStore(storage);
    backend = FakeReadingOperationBackend();
    stagedHands = [];
    analysis = _PalmAnalysis();
    fixturePath = '${root.path}/palm.jpg';
    await File('test/features/palm/fixtures/palm_sample.jpg').copy(fixturePath);
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  /// Records the `handSide` of every staged palm upload, then forwards.
  Future<ReadingOperationWire?> send(
    String method,
    String path,
    Map<String, Object>? body,
  ) {
    if (path.endsWith('/staged-image')) {
      stagedHands.add(body?['handSide'] as String?);
    }
    return backend.send(method, path, body);
  }

  PalmReadingController controller() {
    return PalmReadingController(
      experience: PalmExperienceService(
        store: store,
        analysis: analysis,
        versions: ReadingVersionService(ReadingVersionStore(storage)),
        persistImage: ({required readingId, required sourcePath}) async =>
            sourcePath,
      ),
      images: _Images(fixturePath),
      live: ReadingFeatureRunner(
        stagedImages: ReadingStagedImageGateway(send),
        inputs: ReadingOperationInputGateway(send: send),
        flow: ReadingLiveFlow(
          operations: ReadingOperationGateway(send: send),
          acceleration: ReadingAccelerationClient(send: send),
          send: send,
        ),
      ),
    );
  }

  PalmReading saved(PalmHand hand) => PalmReading(
    id: 'p-hand-${hand.name}',
    createdAt: DateTime.utc(2026, 1, 1),
    hand: hand,
    imagePath: fixturePath,
    overall: 'old-o',
    lifeLine: 'old-l',
    headLine: 'old-h',
    heartLine: 'old-he',
    fateLine: 'old-f',
    takeaway: 'old-t',
    symbols: const ['star'],
    themes: const ['calm'],
  );

  for (final hand in PalmHand.values) {
    test(
      '${hand.name}: selection → staged request → reading → store',
      () async {
        final c = controller();
        c.selectHand(hand);
        c.startCapture();
        c.debugSetImageForTest(CoffeeImagePick(path: fixturePath));
        await c.analyze();

        expect(c.phase, PalmPhase.result, reason: c.errorMessage);
        expect(stagedHands, [hand.name]);
        expect(analysis.hands, [hand]);
        expect(c.reading!.hand, hand);

        final reopened = PalmReadingStore(storage).byId(c.reading!.id)!;
        expect(reopened.hand, hand);
      },
    );

    test('${hand.name}: reopened reading keeps its hand when reinterpreted, '
        'whatever the landing pick is', () async {
      final other = hand == PalmHand.left ? PalmHand.right : PalmHand.left;
      final current = saved(hand);
      await store.save(current);
      final c = controller();
      c.selectHand(other);
      c.openSaved(current);
      await c.reinterpret();

      expect(c.phase, PalmPhase.result, reason: c.errorMessage);
      expect(stagedHands, [hand.name]);
      expect(analysis.hands, [hand]);
      expect(c.reading!.hand, hand);
      expect(store.byId(current.id)!.hand, hand);
    });
  }

  test('legacy saved records keep their stored hand', () async {
    await store.save(saved(PalmHand.left));
    await store.save(saved(PalmHand.right));
    final reopened = PalmReadingStore(storage);
    expect(reopened.byId('p-hand-left')!.hand, PalmHand.left);
    expect(reopened.byId('p-hand-right')!.hand, PalmHand.right);
  });

  test('server hand wire stays exact; unknown is never guessed', () {
    expect(PalmHand.fromWire('left'), PalmHand.left);
    expect(PalmHand.fromWire('right'), PalmHand.right);
    expect(PalmHand.fromWire(null), isNull);
    expect(PalmHand.fromWire('sol'), isNull);
  });
}

class _PalmAnalysis implements PalmAnalysisPort {
  final hands = <PalmHand>[];

  @override
  bool get isAvailable => true;

  @override
  Future<PalmReading> analyze(
    CoffeeImagePick image, {
    required PalmHand hand,
  }) async {
    hands.add(hand);
    return PalmReading(
      id: 'p-fresh-${hands.length}',
      createdAt: DateTime.utc(2026, 1, 2),
      hand: hand,
      imagePath: image.path,
      overall: 'new-o',
      lifeLine: 'new-l',
      headLine: 'new-h',
      heartLine: 'new-he',
      fateLine: 'new-f',
      takeaway: 'new-t',
      symbols: const ['moon'],
      themes: const ['change'],
    );
  }
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
