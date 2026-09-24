/// Phase 6E — immutable Classical dual-run shadow QA result.
library;

import '../../interpretation/models/reading_context.dart';
import '../evidence/narrative_request.dart';
import '../prompt/narrative_tarot_prompt_input.dart';
import 'narrative_tarot_shadow_freeze.dart';
import 'narrative_tarot_shadow_parity.dart';
import 'narrative_tarot_shadow_status.dart';

class NarrativeTarotShadowResult {
  NarrativeTarotShadowResult._({
    required this.status,
    this.inputFailure,
    this.legacyContext,
    this.baseNarrativeRequest,
    this.finalNarrativeRequest,
    this.promptInput,
    Map<String, Object?>? wirePayload,
    this.legacyCacheKey,
    this.narrativeCacheKey,
    this.parity,
    this.structuralFingerprint,
    this.phase5FailureCode,
  }) : wirePayload =
            wirePayload == null ? null : deepFreezeWireMap(wirePayload);

  factory NarrativeTarotShadowResult.terminal({
    required NarrativeTarotShadowStatus status,
    NarrativeTarotShadowInputFailure? inputFailure,
    String? phase5FailureCode,
    ReadingContext? legacyContext,
  }) {
    return NarrativeTarotShadowResult._(
      status: status,
      inputFailure: inputFailure,
      phase5FailureCode: phase5FailureCode,
      legacyContext: legacyContext,
    );
  }

  factory NarrativeTarotShadowResult.ok({
    required ReadingContext legacyContext,
    required TarotNarrativeRequest baseNarrativeRequest,
    required TarotNarrativeRequest finalNarrativeRequest,
    required NarrativeTarotPromptInput promptInput,
    required Map<String, Object?> wirePayload,
    required String legacyCacheKey,
    required String narrativeCacheKey,
    required NarrativeTarotShadowParityReport parity,
    required String structuralFingerprint,
  }) {
    return NarrativeTarotShadowResult._(
      status: NarrativeTarotShadowStatus.pass,
      legacyContext: legacyContext,
      baseNarrativeRequest: baseNarrativeRequest,
      finalNarrativeRequest: finalNarrativeRequest,
      promptInput: promptInput,
      wirePayload: wirePayload,
      legacyCacheKey: legacyCacheKey,
      narrativeCacheKey: narrativeCacheKey,
      parity: parity,
      structuralFingerprint: structuralFingerprint,
    );
  }

  final NarrativeTarotShadowStatus status;
  final NarrativeTarotShadowInputFailure? inputFailure;
  final ReadingContext? legacyContext;
  final TarotNarrativeRequest? baseNarrativeRequest;
  final TarotNarrativeRequest? finalNarrativeRequest;
  final NarrativeTarotPromptInput? promptInput;
  final Map<String, Object?>? wirePayload;
  final String? legacyCacheKey;
  final String? narrativeCacheKey;
  final NarrativeTarotShadowParityReport? parity;
  final String? structuralFingerprint;
  final String? phase5FailureCode;

  bool get isPass => status == NarrativeTarotShadowStatus.pass;
}
