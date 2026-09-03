/// TASK 58 — OR honesty chain: typed failures + quality never fake-live.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/personality/or_response_depth.dart';
import 'package:oracly_new/core/reading/ai_output_quality_kind.dart';
import 'package:oracly_new/core/reading/ai_output_quality_runner.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/ai_request_exception.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/chat_ai_reply.dart';
import 'package:oracly_new/features/ai/production/models/coffee_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/conversation_turn.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/models/palm_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/companion/controllers/companion_controller.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/models/companion_state.dart';
import 'package:oracly_new/features/companion/services/companion_ai_bridge.dart';

void main() {
  test('network failure maps to offline status, not a chat wall', () {
    expect(
      CompanionController.linkForTest(AiFailureKind.network),
      CompanionLinkStatus.offline,
    );
    expect(
      CompanionController.linkForTest(AiFailureKind.timeout),
      CompanionLinkStatus.online,
    );
    expect(
      CompanionController.linkForTest(AiFailureKind.invalidResponse),
      CompanionLinkStatus.online,
    );
    expect(
      CompanionController.linkForTest(AiFailureKind.noConfiguration),
      CompanionLinkStatus.online,
    );
    expect(
      CompanionController.linkForTest(AiFailureKind.unauthorized),
      CompanionLinkStatus.online,
    );
    expect(
      CompanionController.linkForTest(AiFailureKind.providerError),
      CompanionLinkStatus.online,
    );
  });

  test('typed failures keep distinct user copy', () {
    expect(
      CompanionController.surfaceForTest(
        AiRequestException(AiFailure.timeout()),
      ),
      ResilienceCopy.slowResponse,
    );
    expect(
      CompanionController.surfaceForTest(
        AiRequestException(AiFailure.invalidResponse()),
      ),
      ResilienceCopy.aiEmptyResponse,
    );
    expect(
      CompanionController.surfaceForTest(
        AiRequestException(AiFailure.noConfiguration()),
      ),
      ResilienceCopy.aiConfigMissing,
    );
    expect(
      CompanionController.surfaceForTest(
        AiRequestException(AiFailure.unauthorized()),
      ),
      ResilienceCopy.aiUnauthorized,
    );
    expect(
      CompanionController.surfaceForTest(
        AiRequestException(AiFailure.providerError()),
      ),
      ResilienceCopy.aiUnavailable,
    );
    expect(
      CompanionController.surfaceForTest(
        AiRequestException(AiFailure.network()),
      ),
      CompanionCopy.connectionError,
    );
    // Network reachability â‰  every failure. Provider stays online in the strip.
    expect(
      CompanionController.linkForTest(AiFailureKind.providerError),
      CompanionLinkStatus.online,
    );
    expect(
      CompanionCopy.connectionError,
      isNot(equals(CompanionCopy.offline)),
    );
    expect(
      ResilienceCopy.aiUnavailable,
      isNot(equals(ResilienceCopy.offline)),
    );
  });

  test('quality fallback is never returned as live companion text', () async {
    final fallback =
        AiOutputQualityRunner.fallbackFor(AiOutputQualityKind.companion);
    final bridge = CompanionAiBridge(_FallbackTextAi(fallback));
    await expectLater(
      bridge.tryLive(userMessage: 'Selam'),
      throwsA(
        isA<AiRequestException>().having(
          (e) => e.failure.kind,
          'kind',
          AiFailureKind.invalidResponse,
        ),
      ),
    );
    expect(fallback, ResilienceCopy.aiResponseUnavailable);
  });
}

/// Provider returns the quality fallback string — must not be tagged live.
class _FallbackTextAi implements OraclyAiService {
  _FallbackTextAi(this.text);

  final String text;

  @override
  bool get isConfigured => true;

  @override
  bool get allowsLocalFallback => false;

  @override
  bool get visionAvailable => false;

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
      AiOutcome.success(ChatAiReply(text: text));

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
  }) {
    throw UnsupportedError('oracle');
  }

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(DreamAiContext context) {
    throw UnsupportedError('dream');
  }

  @override
  Future<AiOutcome<CoffeeAiAnalysis>> analyzeCoffee({
    required List<int> imageBytes,
    required String mimeType,
  }) {
    throw UnsupportedError('coffee');
  }

  @override
  Future<AiOutcome<PalmAiAnalysis>> analyzePalm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
  }) {
    throw UnsupportedError('palm');
  }
}

