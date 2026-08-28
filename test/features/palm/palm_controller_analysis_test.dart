/// Controller analysis tokens, retry, and duplicate guards — no camera.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:oracly_new/features/palm/controllers/palm_reading_controller.dart';
import 'package:oracly_new/features/palm/models/palm_analysis_error.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/services/palm_analysis_port.dart';
import 'package:oracly_new/features/palm/services/palm_experience_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late String fixturePath;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('palm_ctrl_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    final sample = File('test/features/palm/fixtures/palm_sample.jpg');
    fixturePath = 'palm.jpg';
    await sample.copy(fixturePath);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  PalmReadingController controllerFor(_FakePalmAnalysis analysis) {
    final experience = PalmExperienceService(
      analysis: analysis,
      persistImage: ({required readingId, required sourcePath}) async =>
          sourcePath,
    );
    return PalmReadingController(
      experience: experience,
      images: _FakeImages(fixturePath),
    );
  }

  test('duplicate analyze while analyzing is blocked', () async {
    final analysis = _FakePalmAnalysis(delay: const Duration(milliseconds: 120));
    final controller = controllerFor(analysis);
    await controller.acceptCapturedPath(fixturePath);
    expect(controller.image, isNotNull);

    final first = controller.analyze();
    final second = controller.analyze();
    await Future.wait([first, second]);
    expect(analysis.calls, 1);
    expect(controller.phase, PalmPhase.result);
  });

  test('stale generation token is ignored', () async {
    final analysis = _FakePalmAnalysis(delay: const Duration(milliseconds: 150));
    final controller = controllerFor(analysis);
    await controller.acceptCapturedPath(fixturePath);

    final stale = controller.analyze();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    controller.backToEntry();
    await controller.acceptCapturedPath(fixturePath);
    analysis.delay = Duration.zero;
    await controller.analyze();
    await stale;

    expect(controller.phase, PalmPhase.result);
    expect(analysis.calls, 2);
    expect(controller.reading?.takeaway, 'takeaway-2');
  });

  test('retryAnalysis reuses the same image', () async {
    final analysis = _FakePalmAnalysis(failOnce: true);
    final controller = controllerFor(analysis);
    await controller.acceptCapturedPath(fixturePath);
    final pathBefore = controller.image!.path;

    await controller.analyze();
    expect(controller.phase, PalmPhase.error);
    expect(controller.lastError?.kind, PalmAnalysisErrorKind.network);
    expect(controller.lastError?.canRetrySameImage, isTrue);

    await controller.retryAnalysis();
    expect(controller.phase, PalmPhase.result);
    expect(analysis.calls, 2);
    expect(controller.image?.path, pathBefore);
  });
}

class _FakePalmAnalysis implements PalmAnalysisPort {
  _FakePalmAnalysis({this.delay = Duration.zero, this.failOnce = false});

  Duration delay;
  bool failOnce;
  int calls = 0;

  @override
  bool get isAvailable => true;

  @override
  Future<PalmReading> analyze(
    CoffeeImagePick image, {
    required PalmHand hand,
  }) async {
    calls++;
    final n = calls;
    await Future<void>.delayed(delay);
    if (failOnce && n == 1) {
      throw PalmAnalysisException(
        const PalmAnalysisError(
          PalmAnalysisErrorKind.network,
          'Ağ bağlantısı zayıf.',
        ),
      );
    }
    return PalmReading(
      id: 'palm_fake_$n',
      createdAt: DateTime(2026, 8, 27),
      hand: hand,
      overall: 'Avuç sakin duruyor.',
      takeaway: 'takeaway-$n',
      imagePath: image.path,
    );
  }
}

class _FakeImages implements CoffeeImageInputPort {
  _FakeImages(this.path);
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

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this.root);
  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
  @override
  Future<String?> getApplicationDocumentsPath() async => root;
  @override
  Future<String?> getTemporaryPath() async => root;
  @override
  Future<String?> getApplicationCachePath() async => root;
}
