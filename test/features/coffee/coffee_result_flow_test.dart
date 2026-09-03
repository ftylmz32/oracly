/// Coffee result flow - image to service to result / error / retry / no-dup.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/coffee/controllers/coffee_reading_controller.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/models/coffee_reading.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late String fixturePath;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('coffee_result_flow_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    fixturePath = '${temp.path}/cup.jpg';
    await File('test/features/palm/fixtures/palm_sample.jpg').copy(fixturePath);
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  Future<CoffeeReadingController> controllerFor(
    CoffeeAnalysisPort analysis,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final c = CoffeeReadingController(
      experience: CoffeeExperienceService(
        store: CoffeeReadingStore(LocalStorage(prefs)),
        analysis: analysis,
        persistImage: ({required readingId, required sourcePath}) async =>
            sourcePath,
      ),
      images: _FakeImages(fixturePath),
    );
    await c.acceptCapturedPath(fixturePath);
    return c;
  }

  test('valid image reaches service and success reaches result', () async {
    var calls = 0;
    final c = await controllerFor(_OkAnalysis(onCall: () => calls++));
    expect(c.image, isNotNull);
    await c.analyze();
    expect(calls, 1);
    expect(c.phase, CoffeePhase.result);
    expect(c.reading, isNotNull);
  });

  test('service failure reaches error and retry reuses image', () async {
    var calls = 0;
    final c = await controllerFor(_FailOnceAnalysis(onCall: () => calls++));
    await c.analyze();
    expect(c.phase, CoffeePhase.error);
    expect(c.image, isNotNull);
    await c.analyze();
    expect(calls, 2);
    expect(c.phase, CoffeePhase.result);
  });

  test('repeated submit does not duplicate request', () async {
    final analysis = _SlowOkAnalysis();
    final c = await controllerFor(analysis);
    final first = c.analyze();
    final second = c.analyze();
    analysis.complete();
    await Future.wait([first, second]);
    expect(analysis.calls, 1);
    expect(c.phase, CoffeePhase.result);
  });

  test('back from result returns to entry safely', () async {
    final c = await controllerFor(_OkAnalysis());
    await c.analyze();
    c.backToEntry();
    expect(c.phase, CoffeePhase.entry);
    expect(c.reading, isNull);
  });

  test('result body routes to CoffeeResultView and never silent landing', () {
    final src = File(
      'lib/features/coffee/presentation/reference/coffee_reference_body.dart',
    ).readAsStringSync();
    expect(src, contains('CoffeeResultView('));
    expect(src, contains('CoffeePhase.result when controller.reading != null'));
    expect(src, contains('// Never fall through to landing'));
    expect(src, isNot(contains('_ => landing')));
  });

  test('session provider is not autoDispose', () {
    final src = File('lib/features/coffee/providers/coffee_providers.dart')
        .readAsStringSync();
    expect(src, contains('coffeeReadingControllerProvider'));
    expect(
      src,
      isNot(
        contains(
          'ChangeNotifierProvider.autoDispose<CoffeeReadingController>',
        ),
      ),
    );
  });
}

class _OkAnalysis implements CoffeeAnalysisPort {
  _OkAnalysis({this.onCall});
  final VoidCallback? onCall;
  @override
  bool get isAvailable => true;
  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    onCall?.call();
    return CoffeeReading(
      id: 'c1',
      createdAt: DateTime.utc(2026, 1, 1),
      overall: 'overall',
      love: 'love',
      career: 'career',
      money: 'money',
      nearFuture: 'near',
      takeaway: 'takeaway',
      visualObservation: 'marks',
      symbols: const [],
      imagePath: image.path,
    );
  }
}

class _FailOnceAnalysis implements CoffeeAnalysisPort {
  _FailOnceAnalysis({this.onCall});
  final VoidCallback? onCall;
  var _failed = false;
  @override
  bool get isAvailable => true;
  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    onCall?.call();
    if (!_failed) {
      _failed = true;
      throw CoffeeAnalysisException('fail once');
    }
    return _OkAnalysis().analyze(image);
  }
}

class _SlowOkAnalysis implements CoffeeAnalysisPort {
  var calls = 0;
  final _gate = Completer<void>();
  void complete() {
    if (!_gate.isCompleted) _gate.complete();
  }

  @override
  bool get isAvailable => true;
  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    calls++;
    await _gate.future;
    return _OkAnalysis().analyze(image);
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
      CoffeeImagePick(path: path);
  @override
  Future<CoffeeImagePick?> pickFromGallery() async =>
      CoffeeImagePick(path: path);
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
