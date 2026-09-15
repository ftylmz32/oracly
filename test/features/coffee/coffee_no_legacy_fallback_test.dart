/// BATCH 3A.2 — the live Coffee analysis chain never turns a backend
/// interpretation that fails the composer's trust/quality bar into a
/// fake "successful" reading. A bad backend overall must surface as a
/// typed failure (retry/error state), never a legacy-woven story, and
/// nothing gets persisted when that happens.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/chat_ai_reply.dart';
import 'package:oracly_new/features/ai/production/models/coffee_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/palm_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/coffee/controllers/coffee_reading_controller.dart';
import 'package:oracly_new/features/coffee/data/coffee_reading_store.dart';
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/services/coffee_analysis_port.dart';
import 'package:oracly_new/features/coffee/services/coffee_experience_service.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:oracly_new/features/coffee/services/openai_coffee_analysis.dart';
// Transitive test-only deps already used the same way elsewhere in this
// suite (see coffee_cancel_analysis_test.dart) — not a direct pubspec dep.
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_reading_operation_backend.dart';

const _validAsset = 'lib/assets/images/coffee_ritual_hero.webp';

const _goodOverall =
    'Fincanda beliren yolun bir kısmı yarım kalmış bir kararı hatırlatıyor; '
    'bu ara ver, sonra devam et düşüncesi bugüne kadar hep haklı çıkmış '
    'gibi görünüyor.';

class _ScriptedCoffeeAi implements OraclyAiService {
  _ScriptedCoffeeAi(this.overall);
  final String overall;

  @override
  bool get isConfigured => true;
  @override
  bool get allowsLocalFallback => false;
  @override
  bool get visionAvailable => true;

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffee({
    required List<int> imageBytes,
    required String mimeType,
    Map<String, dynamic>? personalization,
  }) async =>
      AiOutcome.success(
        CoffeeAiAnalysis(
          visualObservation: 'Fincan sakin duruyor.',
          overall: overall,
          love: '',
          career: '',
          money: '',
          nearFuture: '',
          takeaway: 'Yarım kalan işi bugün küçük bir adımla ilerletmek iyi gelebilir.',
        ),
      );

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
    Map<String, dynamic>? personalization,
  }) async =>
      throw UnsupportedError('palm not used in this test');

  @override
  Future<AiOutcome<ChatAiReply>> chat({
    required String userMessage,
    List<String> priorUser = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) async =>
      throw UnsupportedError('chat not used in this test');

  @override
  Future<AiOutcome<ChatAiReply>> askOracle({
    required ReadingAiContext context,
    required String userMessage,
    List<String> priorUser = const [],
    List<String> observedThemes = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) async =>
      throw UnsupportedError('askOracle not used in this test');

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(DreamAiContext context) async =>
      throw UnsupportedError('dream not used in this test');

  @override
  Future<AiOutcome<ChatAiReply>> generateTarotReading({
    required List<Map<String, dynamic>> cards,
    required String spreadLabel,
    String? userQuestion,
    String? readingTheme,
    Map<String, dynamic>? journeyHints,
  }) async =>
      throw UnsupportedError('tarot not used in this test');
}

CoffeeAnalysisPort _portFor(String overall) =>
    OpenAiCoffeeAnalysis(ai: _ScriptedCoffeeAi(overall));

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
  Future<CoffeeImagePick?> pickFromGallery() async => CoffeeImagePick(path: path);
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
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late String fixturePath;

  setUp(() async {
    temp = await Directory.systemTemp.createTemp('coffee_no_legacy_');
    PathProviderPlatform.instance = _FakePathProvider(temp.path);
    final sample = File(_validAsset);
    fixturePath = '${temp.path}/cup.jpg';
    await sample.copy(fixturePath);
  });

  tearDown(() async {
    if (await temp.exists()) await temp.delete(recursive: true);
  });

  Future<CoffeeReadingController> controllerFor(String overall) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final controller = CoffeeReadingController(
      experience: CoffeeExperienceService(
        store: CoffeeReadingStore(storage),
        analysis: _portFor(overall),
        persistImage: ({required readingId, required sourcePath}) async =>
            sourcePath,
      ),
      images: _FakeImages(fixturePath),
      live: fakeImmediateReadingFeatureRunner(),
    );
    controller.startCapture();
    await controller.pickGallery();
    return controller;
  }

  test('A: valid authoritative backend prose is displayed', () async {
    final port = _portFor(_goodOverall);
    final reading = await port.analyze(CoffeeImagePick(path: fixturePath));
    expect(reading.overall, _goodOverall);
  });

  test(
    'B: invalid/robotic/too-short backend prose is never replaced by a '
    'legacy-woven story — the analysis fails outright',
    () async {
      final port = _portFor('Kısa.');
      await expectLater(
        port.analyze(CoffeeImagePick(path: fixturePath)),
        throwsA(isA<CoffeeAnalysisException>()),
      );
    },
  );

  test('C: invalid backend prose surfaces through the typed retry/error path', () async {
    final controller = await controllerFor('Kısa.');
    await controller.analyze();
    expect(controller.phase, CoffeePhase.error);
    expect(controller.errorMessage, isNotNull);
    expect(controller.reading, isNull);
  });

  test(
    'D: no observation-heavy/legacy fallback reaches the result UI or '
    'gets persisted to history when the backend interpretation fails',
    () async {
      final controller = await controllerFor('Kuş = haber.');
      await controller.analyze();
      expect(controller.phase, isNot(CoffeePhase.result));
      expect(controller.reading, isNull);
      await controller.loadHistory();
      expect(controller.history, isEmpty);
    },
  );

  test('a good reading still reaches CoffeePhase.result and is persisted', () async {
    final controller = await controllerFor(_goodOverall);
    await controller.analyze();
    expect(controller.phase, CoffeePhase.result);
    expect(controller.reading?.overall, _goodOverall);
    await controller.loadHistory();
    expect(controller.history, hasLength(1));
  });
}
