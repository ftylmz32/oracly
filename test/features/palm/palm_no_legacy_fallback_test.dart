/// BATCH 3A.2 — the live Palm analysis chain never turns a backend
/// interpretation that fails the composer's trust/quality bar into a
/// fake "successful" reading. A bad backend overall must surface as a
/// typed failure (retry/error state), never a legacy-woven story, and
/// nothing gets persisted when that happens.
library;

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
import 'package:oracly_new/features/coffee/models/coffee_image_pick.dart';
import 'package:oracly_new/features/coffee/services/coffee_image_input_port.dart';
import 'package:oracly_new/features/palm/controllers/palm_reading_controller.dart';
import 'package:oracly_new/features/palm/data/palm_reading_store.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/services/openai_palm_analysis.dart';
import 'package:oracly_new/features/palm/services/palm_analysis_port.dart';
import 'package:oracly_new/features/palm/services/palm_experience_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_reading_operation_backend.dart';

const _validAsset = 'lib/assets/images/coffee_ritual_hero.webp';

const _goodOverall =
    'Bu avuç içinde kararların genelde sessizce, uzun bir düşünme süresinin '
    'ardından alındığı görülüyor; hızlı davranmak yerine oturup tartmayı '
    'tercih eden bir yapı bu.';

class _ScriptedPalmAi implements OraclyAiService {
  _ScriptedPalmAi(this.overall);
  final String overall;

  @override
  bool get isConfigured => true;
  @override
  bool get allowsLocalFallback => false;
  @override
  bool get visionAvailable => true;

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
    Map<String, dynamic>? personalization,
  }) async =>
      AiOutcome.success(
        PalmAiAnalysis(
          overall: overall,
          takeaway: 'Bugün acele etmeden tek bir karara odaklanmak yeterli.',
        ),
      );

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffee({
    required List<int> imageBytes,
    required String mimeType,
    Map<String, dynamic>? personalization,
  }) async =>
      throw UnsupportedError('coffee not used in this test');

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

PalmAnalysisPort _portFor(String overall) =>
    OpenAiPalmAnalysis(ai: _ScriptedPalmAi(overall));

Future<(PalmReadingController, PalmReadingStore)> _controllerFor(String overall) async {
  SharedPreferences.setMockInitialValues({});
  final storage = LocalStorage(await SharedPreferences.getInstance());
  final store = PalmReadingStore(storage);
  final controller = PalmReadingController(
    experience: PalmExperienceService(
      analysis: _portFor(overall),
      store: store,
      persistImage: ({required readingId, required sourcePath}) async =>
          sourcePath,
    ),
    images: const _UnusedImages(),
    live: fakeImmediateReadingFeatureRunner(),
  );
  controller.startCapture();
  controller.selectHand(PalmHand.right);
  controller.debugSetImageForTest(const CoffeeImagePick(path: _validAsset));
  return (controller, store);
}

class _UnusedImages implements CoffeeImageInputPort {
  const _UnusedImages();
  @override
  bool get cameraAvailable => false;
  @override
  bool get galleryAvailable => false;
  @override
  Future<CoffeeImagePick?> pickFromCamera() async => null;
  @override
  Future<CoffeeImagePick?> pickFromGallery() async => null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('A: valid authoritative backend prose is displayed', () async {
    final port = _portFor(_goodOverall);
    final reading = await port.analyze(
      const CoffeeImagePick(path: _validAsset),
      hand: PalmHand.right,
    );
    expect(reading.overall, _goodOverall);
  });

  test(
    'B: invalid/robotic/too-short backend prose is never replaced by a '
    'legacy-woven story — the analysis fails outright',
    () async {
      final port = _portFor('Kısa.');
      await expectLater(
        port.analyze(const CoffeeImagePick(path: _validAsset), hand: PalmHand.right),
        throwsA(isA<PalmAnalysisException>()),
      );
    },
  );

  test('C: invalid backend prose surfaces through the typed retry/error path', () async {
    final (controller, _) = await _controllerFor('Kısa.');
    await controller.analyze();
    expect(controller.phase, PalmPhase.error);
    expect(controller.errorMessage, isNotNull);
    expect(controller.reading, isNull);
  });

  test(
    'D: no observation-heavy/legacy fallback reaches the result UI or '
    'gets persisted to history when the backend interpretation fails',
    () async {
      final (controller, store) = await _controllerFor('Kalp = aşk. Zihin = zeka.');
      await controller.analyze();
      expect(controller.phase, isNot(PalmPhase.result));
      expect(controller.reading, isNull);
      expect(store.all(), isEmpty);
    },
  );

  test('a good reading still reaches PalmPhase.result and is persisted', () async {
    final (controller, store) = await _controllerFor(_goodOverall);
    await controller.analyze();
    expect(controller.phase, PalmPhase.result);
    expect(controller.reading?.overall, _goodOverall);
    expect(store.all(), hasLength(1));
  });
}
