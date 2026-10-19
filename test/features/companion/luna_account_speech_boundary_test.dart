/// Luna speech stays with the account that received it.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe.dart';
import 'package:oracly_new/core/auth/user_local_data_wipe_result.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_ai_conversation_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/intelligence/data/intelligence_index_store.dart';
import 'package:oracly_new/core/intelligence/data/local_intelligence_repository.dart';
import 'package:oracly_new/core/intelligence/data/ritual_history_reader.dart';
import 'package:oracly_new/core/intelligence/services/intelligence_layer_service.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/core/storage/in_memory_secure_storage.dart';
import 'package:oracly_new/core/voice/or_speech_grant.dart';
import 'package:oracly_new/core/voice/or_speech_speed.dart';
import 'package:oracly_new/core/voice/oracly_proxy_speech.dart';
import 'package:oracly_new/core/voice/oracly_tts_gate.dart';
import 'package:oracly_new/core/voice/oracly_tts_port.dart';
import 'package:oracly_new/core/voice/oracly_voice_id.dart';
import 'package:oracly_new/features/ai/domain/models/ai_message.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context.dart';
import 'package:oracly_new/features/ai/oracle_conversation/services/oracle_ai_message_source.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/chat_ai_reply.dart';
import 'package:oracly_new/features/ai/production/models/coffee_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/palm_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/ai/production/transport/ai_proxy_request.dart';
import 'package:oracly_new/features/ai/production/transport/ai_transport.dart';
import 'package:oracly_new/features/companion/controllers/companion_controller.dart';
import 'package:oracly_new/features/companion/controllers/companion_output_controller.dart';
import 'package:oracly_new/features/companion/models/companion_response.dart';
import 'package:oracly_new/features/companion/models/companion_send_result.dart';
import 'package:oracly_new/features/companion/models/companion_state.dart';
import 'package:oracly_new/features/companion/models/conversation.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/or_chat_output_mode.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/services/companion_experience_service.dart';
import 'package:oracly_new/features/companion/services/companion_memory_service.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';
import 'package:oracly_new/services/memory_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _grantA = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
const _grantB = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';

const _oracle = OracleReadingContext(
  sessionId: 's1',
  spreadLabel: 'Tek',
  deckId: 'd',
  deckName: 'D',
  readingTitle: 'T',
  cardsSummary: 'C',
  interpretationSummary: 'Ozet',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _HoldTts tts;
  late CompanionOutputController output;
  late int epoch;

  setUp(() {
    epoch = UserLocalDataIsolation.accountSwitchEpoch.value;
    tts = _HoldTts();
    OraclyTtsGate.bind(
      service: tts,
      enabled: true,
      style: AiPersonality.mystical,
      language: 'tr',
    );
    output = CompanionOutputController(
      persistMode: (_) async {},
      readMode: () => OrChatOutputMode.voice,
    );
    OraclyProxySpeech.resetCache();
  });

  tearDown(() {
    output.dispose();
    OraclyTtsGate.engine = null;
    OraclyTtsGate.voiceRepliesEnabled = false;
    OraclyTtsGate.speaking.value = false;
    OraclyTtsGate.paused.value = false;
    OraclyTtsGate.unavailable.value = false;
    OraclyProxySpeech.resetCache();
    UserLocalDataIsolation.accountSwitchEpoch.value = epoch;
  });

  test('logout clears the clip, playback, and speech grant', () async {
    await _seedClip();
    expect(OraclyProxySpeech.debugCacheLength, 1);
    await output.speakNow('A yaniti', speechGrant: _grantA);
    expect(output.debugLastSpeechGrant, _grantA);
    expect(output.canReplay, isTrue);

    final wiped = await _wipe();
    expect(wiped.isComplete, isTrue, reason: '${wiped.failedOperations}');
    expect(output.debugLastSpeechGrant, isNull);
    expect(output.canReplay, isFalse);
    expect(OraclyProxySpeech.debugCacheLength, 0);
    expect(tts.stopCount, greaterThan(0));
    expect(OraclyTtsGate.speaking.value, isFalse);
  });

  test('direct account switch drops A and then speaks only B', () async {
    final storage = await _disk();
    final isolation = UserLocalDataIsolation(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
    final signedA = await isolation.onSignedIn('account-a');
    expect(signedA.success, isTrue);
    expect(UserLocalDataIsolation.accountSwitchEpoch.value, epoch);

    await output.speakNow('A yaniti', speechGrant: _grantA);
    final boundary = CompanionOutputController.speechBoundary;
    final signedB = await isolation.onSignedIn('account-b');

    expect(signedB.success, isTrue);
    expect(UserLocalDataIsolation.accountSwitchEpoch.value, epoch + 1);
    expect(CompanionOutputController.speechBoundary, boundary + 1);
    expect(output.debugLastSpeechGrant, isNull);
    expect(output.canReplay, isFalse);

    final played = tts.spoken.length;
    await output.speakNow('B yaniti', speechGrant: _grantB);
    expect(tts.spoken.sublist(played), ['B yaniti']);
    expect(output.debugLastSpeechGrant, _grantB);
  });

  test('same account sign-in keeps the current speech grant', () async {
    final storage = await _disk();
    final isolation = UserLocalDataIsolation(
      storage,
      secureStorage: InMemorySecureStorage(),
    );
    await isolation.onSignedIn('account-a');
    await output.speakNow('A yaniti', speechGrant: _grantA);
    final boundary = CompanionOutputController.speechBoundary;

    final again = await isolation.onSignedIn('account-a');

    expect(again.success, isTrue);
    expect(CompanionOutputController.speechBoundary, boundary);
    expect(output.debugLastSpeechGrant, _grantA);
    expect(output.canReplay, isTrue);
  });

  test('a late speak for A does not play after the account boundary', () async {
    final boundary = CompanionOutputController.speechBoundary;
    tts.hold = Completer<void>();
    final pending = output.speakIfVoice(
      'A sesi',
      speechGrant: _grantA,
      speechBoundary: boundary,
    );
    await _until(() => tts.started);
    await CompanionOutputController.dropSessionSpeech();
    tts.hold!.complete();
    await pending;

    expect(output.debugLastSpeechGrant, isNull);
    expect(output.canReplay, isFalse);
    expect(tts.spoken, isEmpty);
    expect(tts.stopCount, greaterThan(0));

    await output.speakIfVoice(
      'A geciken',
      speechGrant: _grantA,
      speechBoundary: boundary,
    );
    expect(tts.spoken, isEmpty);

    await output.speakNow('B yaniti', speechGrant: _grantB);
    expect(tts.spoken, ['B yaniti']);
    expect(output.debugLastSpeechGrant, _grantB);
  });

  test('an in-flight Luna reply does not land on the next account', () async {
    final deferred = _deferred();
    final controller = CompanionController(deferred, output);
    addTearDown(controller.dispose);
    controller.seedSessionForTest(
      conversation: _thread(),
      phase: CompanionPhase.conversing,
    );

    final pending = controller.send('A sorusu');
    await _until(() => deferred.calls == 1);
    await CompanionOutputController.dropSessionSpeech();
    deferred.complete('A gizli yanit', _grantA);
    await pending;

    final messages = controller.state.conversation?.messages ?? const [];
    expect(messages.any((m) => m.content.contains('A gizli')), isFalse);
    expect(tts.spoken, isEmpty);
    expect(output.debugLastSpeechGrant, isNull);
  });

  test('the same account still speaks each reply with its own grant', () async {
    final boundary = CompanionOutputController.speechBoundary;
    await output.speakNow('Birinci', speechGrant: _grantA);
    await output.speakNow('Ikinci', speechGrant: _grantB);

    expect(CompanionOutputController.speechBoundary, boundary);
    expect(tts.spoken, ['Birinci', 'Ikinci']);
    expect(output.debugLastSpeechGrant, _grantB);
    expect(output.canReplay, isTrue);
  });

  test('leaving the screen does not drop the message speech right', () async {
    final metadata = <String, String>{OrSpeechGrant.metadataKey: _grantA};
    await output.speakNow('A yaniti', speechGrant: OrSpeechGrant.of(metadata));
    final boundary = CompanionOutputController.speechBoundary;

    await OraclyTtsGate.interrupt();
    OraclyProxySpeech.releaseCaches();

    expect(CompanionOutputController.speechBoundary, boundary);
    expect(metadata[OrSpeechGrant.metadataKey], _grantA);
    expect(output.debugLastSpeechGrant, _grantA);
    await output.speakNow('A yaniti', speechGrant: OrSpeechGrant.of(metadata));
    expect(output.debugLastSpeechGrant, _grantA);
    expect(tts.spoken.last, 'A yaniti');
  });

  test('a late oracle reply cannot keep the previous grant', () async {
    final ai = _HangAi();
    final source = OracleAiMessageSource(ai: ai);
    final pending = source
        .stream(context: _oracle, userMessage: 'soru')
        .toList();
    await _until(() => ai.started);
    OracleAiMessageSource.dropSessionGrant();
    ai.finish(const ChatAiReply(text: 'gizli oracle', speechGrant: _grantA));

    expect(await pending, isEmpty);
    expect(source.speechGrant, isNull);
  });

  test('an oracle reply on the same account keeps its grant', () async {
    final ai = _HangAi()
      ..finish(const ChatAiReply(text: 'acik oracle', speechGrant: _grantB));
    final source = OracleAiMessageSource(ai: ai);

    final text = await source.reply(context: _oracle, userMessage: 'soru');

    expect(text, isNotEmpty);
    expect(source.speechGrant, _grantB);
  });
}

Future<void> _until(bool Function() ready) async {
  for (var i = 0; i < 40 && !ready(); i++) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(ready(), isTrue);
}

Future<LocalStorage> _disk() async {
  final root = await Directory.systemTemp.createTemp('oracly-luna-boundary-');
  addTearDown(() => root.delete(recursive: true));
  PathProviderPlatform.instance = _TempPath(root.path);
  SharedPreferences.setMockInitialValues({});
  return LocalStorage.open();
}

Future<UserLocalDataWipeResult> _wipe() async {
  final storage = await _disk();
  return UserLocalDataWipe.run(storage, secureStorage: InMemorySecureStorage());
}

Future<void> _seedClip() async {
  final clip = await OraclyProxySpeech(_ClipTransport()).synthesize(
    text: 'A yaniti',
    personality: AiPersonality.mystical,
    speechGrant: _grantA,
  );
  expect(clip, isNotNull);
}

Conversation _thread() {
  final now = DateTime.now();
  return Conversation(
    id: 'c1',
    title: 'OR',
    topic: ConversationTopic.general,
    messages: [
      AIMessage(
        id: 'welcome_1',
        role: AIMessageRole.assistant,
        content: 'Hos geldin.',
        createdAt: now,
      ),
    ],
    createdAt: now,
    updatedAt: now,
  );
}

_DeferredExperience _deferred() {
  final storage = LocalStorage.ephemeral();
  final conversations = LocalAiConversationRepository(storage);
  return _DeferredExperience(
    conversationRepository: conversations,
    intelligence: IntelligenceLayerService(
      LocalIntelligenceRepository(
        history: MockHistoryRepository(storage),
        conversations: conversations,
        ritualHistory: RitualHistoryReader(storage),
        indexStore: IntelligenceIndexStore(storage),
      ),
    ),
    memoryService: CompanionMemoryService(MemoryService(storage)),
  );
}

class _TempPath extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _TempPath(this.root);
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

class _HoldTts implements OraclyTtsPort {
  final spoken = <String>[];
  var stopCount = 0;
  var started = false;
  var speaking = false;
  Completer<void>? hold;

  @override
  void Function(bool isSpeaking)? onSpeakingChanged;

  @override
  bool get isSpeaking => speaking;

  @override
  bool get lastSpeakFailed => false;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<void> speak(
    String text, {
    required AiPersonality personality,
    String languageCode = 'tr',
    OraclyVoiceId voice = OraclyVoiceId.warm,
    OrSpeechSpeed speed = OrSpeechSpeed.normal,
  }) async {
    started = true;
    speaking = true;
    onSpeakingChanged?.call(true);
    final gate = hold;
    final stopsBefore = stopCount;
    if (gate != null) await gate.future;
    if (stopCount > stopsBefore) {
      speaking = false;
      return;
    }
    spoken.add(text.trim());
    speaking = false;
    onSpeakingChanged?.call(false);
  }

  @override
  Future<void> stop() async {
    stopCount++;
    speaking = false;
    onSpeakingChanged?.call(false);
  }
}

class _ClipTransport implements AiTransport {
  @override
  Future<AiOutcome<Map<String, dynamic>>> execute(
    AiProxyRequest request,
  ) async {
    return AiOutcome.success({
      'audioBase64': base64Encode(List<int>.filled(32, 9)),
      'mimeType': 'audio/mpeg',
    });
  }
}

class _DeferredExperience extends CompanionExperienceService {
  _DeferredExperience({
    required super.conversationRepository,
    required super.intelligence,
    required super.memoryService,
  });

  final Completer<({String text, String grant})> _gate = Completer();
  var calls = 0;

  void complete(String text, String grant) {
    if (!_gate.isCompleted) _gate.complete((text: text, grant: grant));
  }

  @override
  Future<CompanionSendResult> send({
    required Conversation conversation,
    required ReflectionContext context,
    required InsightRequest request,
    OracleReadingContext? readingContext,
  }) async {
    calls++;
    final reply = await _gate.future;
    final now = DateTime.now();
    return CompanionSendResult(
      conversation: conversation.copyWith(
        messages: [
          ...conversation.messages,
          AIMessage(
            id: 'msg_a_late',
            role: AIMessageRole.assistant,
            content: reply.text,
            createdAt: now,
            metadata: {OrSpeechGrant.metadataKey: reply.grant},
          ),
        ],
        updatedAt: now,
      ),
      response: CompanionResponse(body: reply.text, speechGrant: reply.grant),
      fromAi: true,
    );
  }
}

class _HangAi implements OraclyAiService {
  final Completer<ChatAiReply> _gate = Completer();
  var started = false;

  void finish(ChatAiReply reply) {
    if (!_gate.isCompleted) _gate.complete(reply);
  }

  @override
  bool get isConfigured => true;
  @override
  bool get allowsLocalFallback => false;
  @override
  bool get visionAvailable => false;

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
  }) async {
    started = true;
    final reply = await _gate.future;
    return AiOutcome.success(reply);
  }

  @override
  Future<AiOutcome<ChatAiReply>> chat({
    required String userMessage,
    List<String> priorUser = const [],
    String? styleHint,
    String? personality,
    List<ConversationTurn> turns = const [],
    OrResponseDepth depth = OrResponseDepth.fallback,
    bool spoken = false,
  }) => throw UnsupportedError('chat');

  @override
  Future<AiOutcome<ChatAiReply>> generateTarotReading({
    required List<Map<String, dynamic>> cards,
    required String spreadLabel,
    String? userQuestion,
    String? readingTheme,
    Map<String, dynamic>? journeyHints,
  }) => throw UnsupportedError('tarot');

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(DreamAiContext context) =>
      throw UnsupportedError('dream');

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffee({
    required List<int> imageBytes,
    required String mimeType,
    Map<String, dynamic>? personalization,
  }) => throw UnsupportedError('coffee');

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
    Map<String, dynamic>? personalization,
  }) => throw UnsupportedError('palm');
}
