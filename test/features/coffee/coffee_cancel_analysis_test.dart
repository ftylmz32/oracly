/// Coffee analysis cancel honesty — leave mid-analyze must not apply result.
library;

import 'dart:async';
import 'dart:io';

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
    temp = await Directory.systemTemp.createTemp('coffee_cancel_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    final sample = File('test/features/palm/fixtures/palm_sample.jpg');
    fixturePath = '${temp.path}/cup.jpg';
    await sample.copy(fixturePath);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  Future<CoffeeReadingController> build(_SlowAnalysis analysis) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final controller = CoffeeReadingController(
      experience: CoffeeExperienceService(
        store: CoffeeReadingStore(LocalStorage(prefs)),
        analysis: analysis,
        persistImage: ({required readingId, required sourcePath}) async =>
            sourcePath,
      ),
      images: _FakeImages(fixturePath),
    );
    controller.startCapture();
    await controller.pickGallery();
    return controller;
  }

  test('stale analyze after backToEntry is ignored', () async {
    final analysis = _SlowAnalysis();
    final controller = await build(analysis);
    expect(controller.image, isNotNull);

    final pending = controller.analyze();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(controller.phase, CoffeePhase.analyzing);
    controller.backToEntry();
    expect(controller.phase, CoffeePhase.entry);
    analysis.complete();
    await pending;

    expect(controller.phase, CoffeePhase.entry);
    expect(controller.reading, isNull);
    expect(analysis.calls, 1);
  });

  test('duplicate analyze while analyzing is blocked', () async {
    final analysis = _SlowAnalysis();
    final controller = await build(analysis);

    final first = controller.analyze();
    final second = controller.analyze();
    analysis.complete();
    await Future.wait([first, second]);
    expect(analysis.calls, 1);
    expect(controller.phase, CoffeePhase.result);
  });
}

class _SlowAnalysis implements CoffeeAnalysisPort {
  final _ready = Completer<void>();
  var calls = 0;

  void complete() {
    if (!_ready.isCompleted) _ready.complete();
  }

  @override
  bool get isAvailable => true;

  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    calls += 1;
    await _ready.future;
    return CoffeeReading(
      id: 'c$calls',
      createdAt: DateTime.now(),
      overall: 'overall',
      love: 'love',
      career: 'career',
      money: 'money',
      nearFuture: 'near',
      takeaway: 'takeaway-$calls',
    );
  }
}

class _FakeImages implements CoffeeImageInputPort {
  const _FakeImages(this.path);
  final String path;
  @override
  bool get cameraAvailable => false;
  @override
  bool get galleryAvailable => true;
  @override
  Future<CoffeeImagePick?> pickFromCamera() async => null;
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
  Future<String?> getTemporaryPath() async => root;
}
