/// Palm result flow - image to service to result / error / retry / no-dup.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
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
    temp = await Directory.systemTemp.createTemp('palm_result_flow_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    fixturePath = '${temp.path}/palm.jpg';
    await File('test/features/palm/fixtures/palm_sample.jpg').copy(fixturePath);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  PalmReadingController controllerFor(PalmAnalysisPort analysis) {
    return PalmReadingController(
      experience: PalmExperienceService(
        analysis: analysis,
        persistImage: ({required readingId, required sourcePath}) async =>
            sourcePath,
      ),
      images: _FakeImages(fixturePath),
    );
  }

  test('valid image reaches service and success reaches result', () async {
    var calls = 0;
    final c = controllerFor(_OkAnalysis(onCall: () => calls++));
    await c.acceptCapturedPath(fixturePath);
    expect(c.image, isNotNull);
    await c.analyze();
    expect(calls, 1);
    expect(c.phase, PalmPhase.result);
    expect(c.reading, isNotNull);
  });

  test('service failure reaches error and retry reuses image', () async {
    var calls = 0;
    final c = controllerFor(_FailOnceAnalysis(onCall: () => calls++));
    await c.acceptCapturedPath(fixturePath);
    await c.analyze();
    expect(c.phase, PalmPhase.error);
    expect(c.image, isNotNull);
    await c.retryAnalysis();
    expect(calls, 2);
    expect(c.phase, PalmPhase.result);
  });

  test('repeated submit does not duplicate request', () async {
    final analysis = _SlowOkAnalysis();
    final c = controllerFor(analysis);
    await c.acceptCapturedPath(fixturePath);
    final first = c.analyze();
    final second = c.analyze();
    analysis.complete();
    await Future.wait([first, second]);
    expect(analysis.calls, 1);
    expect(c.phase, PalmPhase.result);
  });

  test('back from result returns to entry safely', () async {
    final c = controllerFor(_OkAnalysis());
    await c.acceptCapturedPath(fixturePath);
    await c.analyze();
    c.backToEntry();
    expect(c.phase, PalmPhase.entry);
    expect(c.reading, isNull);
  });

  test('result body routes to PalmResultView and never silent landing', () {
    final src = File(
      'lib/features/palm/presentation/palm_reference_body.dart',
    ).readAsStringSync();
    expect(src, contains('PalmResultView('));
    expect(src, contains('PalmPhase.result when controller.reading != null'));
    expect(src, contains('// Never fall through to landing'));
    expect(src, isNot(contains('_ => landing')));
  });

  test('session provider is not autoDispose', () {
    final src = File('lib/features/palm/providers/palm_providers.dart')
        .readAsStringSync();
    expect(src, contains('palmReadingControllerProvider'));
    expect(
      src,
      isNot(
        contains(
          'ChangeNotifierProvider.autoDispose<PalmReadingController>',
        ),
      ),
    );
  });
}

class _OkAnalysis implements PalmAnalysisPort {
  _OkAnalysis({this.onCall});
  final VoidCallback? onCall;
  @override
  bool get isAvailable => true;
  @override
  Future<PalmReading> analyze(
    CoffeeImagePick image, {
    required PalmHand hand,
  }) async {
    onCall?.call();
    return PalmReading(
      id: 'p1',
      createdAt: DateTime.utc(2026, 1, 1),
      hand: hand,
      overall: 'overall',
      takeaway: 'takeaway',
      imagePath: image.path,
    );
  }
}

class _FailOnceAnalysis implements PalmAnalysisPort {
  _FailOnceAnalysis({this.onCall});
  final VoidCallback? onCall;
  var _failed = false;
  @override
  bool get isAvailable => true;
  @override
  Future<PalmReading> analyze(
    CoffeeImagePick image, {
    required PalmHand hand,
  }) async {
    onCall?.call();
    if (!_failed) {
      _failed = true;
      throw const PalmAnalysisException(
        PalmAnalysisError(PalmAnalysisErrorKind.network, 'fail once'),
      );
    }
    return _OkAnalysis().analyze(image, hand: hand);
  }
}

class _SlowOkAnalysis implements PalmAnalysisPort {
  var calls = 0;
  final _gate = Completer<void>();
  void complete() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  bool get isAvailable => true;
  @override
  Future<PalmReading> analyze(
    CoffeeImagePick image, {
    required PalmHand hand,
  }) async {
    calls++;
    await _gate.future;
    return _OkAnalysis().analyze(image, hand: hand);
  }
}

class _FakeImages implements CoffeeImageInputPort {
  const _FakeImages(this.path);
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
  Future<String?> getApplicationDocumentsPath() async => root;
  @override
  Future<String?> getApplicationSupportPath() async => root;
  @override
  Future<String?> getTemporaryPath() async => root;
  @override
  Future<String?> getApplicationCachePath() async => root;
}
