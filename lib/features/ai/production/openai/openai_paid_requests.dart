/// Paid-op proxy payloads — binder Idempotency-Key when a charge is in flight.
library;

import 'dart:convert';

import '../../services/prompt_sanitizer.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../reading_operation/services/reading_operation_context.dart';
import '../ai_request_fingerprint.dart';
import '../contexts/reading_ai_context.dart';
import '../transport/ai_operation.dart';
import '../transport/ai_proxy_request.dart';
import '../../../tarot/narrative/live/narrative_tarot_attempt.dart';
import 'paid_request_idempotency.dart';

abstract final class OpenAiPaidRequests {
  OpenAiPaidRequests._();

  static AiProxyRequest dream({
    required String model,
    required DreamAiContext context,
  }) {
    final fp = AiRequestFingerprint.text(
      'dream',
      '${context.narrative}|${context.memorySummary ?? ''}',
    );
    return AiProxyRequest(
      operation: AiOperation.dreamAnalysis,
      model: model,
      idempotencyKey: PaidRequestIdempotency.resolve(fp),
      payload: {
        'narrative': PromptSanitizer.sanitize(context.narrative),
        'symbols': context.symbols,
        'emotions': context.emotions,
        if (context.memorySummary?.trim().isNotEmpty == true)
          'memorySummary': PromptSanitizer.sanitize(context.memorySummary!),
        ..._language,
      },
    );
  }

  static AiProxyRequest coffee({
    required String model,
    required List<int> imageBytes,
    required String mimeType,
    Map<String, dynamic>? personalization,
    String? readingPhase,
    String? readingBridgeKey,
    String? observationToken,
  }) {
    final fp = AiRequestFingerprint.image('coffee', imageBytes);
    final operationId = ReadingOperationContext.currentOperationId;
    return AiProxyRequest(
      operation: AiOperation.coffeeAnalysis,
      model: model,
      idempotencyKey:
          '${PaidRequestIdempotency.resolve(fp)}${readingPhase == null ? '' : ':$readingPhase'}',
      payload: {
        'mimeType': mimeType.trim().toLowerCase(),
        if (operationId == null && readingPhase != 'write')
          'imageBase64': base64Encode(imageBytes),
        if (operationId == null && readingPhase != 'write')
          'byteLength': imageBytes.length,
        'operationId': ?operationId,
        'readingPhase': ?readingPhase,
        'readingBridgeKey': ?readingBridgeKey,
        'observationToken': ?observationToken,
        if (personalization != null && personalization.isNotEmpty)
          'personalization': personalization,
        ..._language,
      },
    );
  }

  static AiProxyRequest palm({
    required String model,
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
    Map<String, dynamic>? personalization,
    String? readingPhase,
    String? readingBridgeKey,
    String? observationToken,
  }) {
    final fp = AiRequestFingerprint.image('palm', imageBytes, hand);
    final operationId = ReadingOperationContext.currentOperationId;
    return AiProxyRequest(
      operation: AiOperation.palmAnalysis,
      model: model,
      idempotencyKey:
          '${PaidRequestIdempotency.resolve(fp)}${readingPhase == null ? '' : ':$readingPhase'}',
      payload: {
        'mimeType': mimeType.trim().toLowerCase(),
        if (operationId == null && readingPhase != 'write')
          'imageBase64': base64Encode(imageBytes),
        if (operationId == null && readingPhase != 'write')
          'byteLength': imageBytes.length,
        'operationId': ?operationId,
        'hand': hand,
        'readingPhase': ?readingPhase,
        'readingBridgeKey': ?readingBridgeKey,
        'observationToken': ?observationToken,
        if (personalization != null && personalization.isNotEmpty)
          'personalization': personalization,
        ..._language,
      },
    );
  }

  /// Coffee analysis resumed from the server-staged image only — no local
  /// bytes exist client-side (app restart / controller disposal lost
  /// them). The fingerprint is derived from `operationId` itself, which
  /// is already a unique per-attempt identifier, rather than from bytes
  /// that are not available here.
  static AiProxyRequest coffeeStaged({
    required String model,
    required String operationId,
    required String mimeType,
    Map<String, dynamic>? personalization,
    String? readingPhase,
    String? readingBridgeKey,
    String? observationToken,
  }) {
    final fp = AiRequestFingerprint.text('coffee_staged', operationId);
    return AiProxyRequest(
      operation: AiOperation.coffeeAnalysis,
      model: model,
      idempotencyKey:
          '${PaidRequestIdempotency.resolve(fp)}${readingPhase == null ? '' : ':$readingPhase'}',
      payload: {
        'mimeType': mimeType.trim().toLowerCase(),
        'operationId': operationId,
        'readingPhase': ?readingPhase,
        'readingBridgeKey': ?readingBridgeKey,
        'observationToken': ?observationToken,
        if (personalization != null && personalization.isNotEmpty)
          'personalization': personalization,
        ..._language,
      },
    );
  }

  /// Palm analysis resumed from the server-staged image only — see
  /// [coffeeStaged].
  static AiProxyRequest palmStaged({
    required String model,
    required String operationId,
    required String mimeType,
    required String hand,
    Map<String, dynamic>? personalization,
    String? readingPhase,
    String? readingBridgeKey,
    String? observationToken,
  }) {
    final fp = AiRequestFingerprint.text('palm_staged', '$operationId|$hand');
    return AiProxyRequest(
      operation: AiOperation.palmAnalysis,
      model: model,
      idempotencyKey:
          '${PaidRequestIdempotency.resolve(fp)}${readingPhase == null ? '' : ':$readingPhase'}',
      payload: {
        'mimeType': mimeType.trim().toLowerCase(),
        'operationId': operationId,
        'hand': hand,
        'readingPhase': ?readingPhase,
        'readingBridgeKey': ?readingBridgeKey,
        'observationToken': ?observationToken,
        if (personalization != null && personalization.isNotEmpty)
          'personalization': personalization,
        ..._language,
      },
    );
  }

  static AiProxyRequest tarotReading({
    required List<Map<String, dynamic>> cards,
    required String spreadLabel,
    String? userQuestion,
    String? readingTheme,
    Map<String, dynamic>? journeyHints,
  }) {
    final cardsKey = cards
        .map((c) => '${c['name']}:${c['positionLabel']}:${c['reversed']}')
        .join(',');
    final fp = AiRequestFingerprint.text('tarot', cardsKey);
    return AiProxyRequest(
      operation: AiOperation.tarotReading,
      idempotencyKey: PaidRequestIdempotency.resolve(fp),
      payload: {
        'cards': cards,
        'spreadLabel': spreadLabel,
        if (userQuestion != null && userQuestion.trim().isNotEmpty)
          'userQuestion': PromptSanitizer.sanitize(userQuestion),
        if (readingTheme != null && readingTheme.trim().isNotEmpty)
          'readingTheme': readingTheme,
        if (journeyHints != null) 'journeyHints': journeyHints,
        ..._language,
      },
    );
  }

  /// Narrative V2 — backend-authoritative writer; no client model hint.
  /// [attempt] is transport idempotency only (`:nv2:a1` / `:nv2:a2`).
  static AiProxyRequest tarotNarrative({
    required Map<String, dynamic> payload,
    required String fingerprint,
    int attempt = 1,
  }) {
    return AiProxyRequest(
      operation: AiOperation.tarotReading,
      idempotencyKey: NarrativeTarotAttempt.idempotencyKey(fingerprint, attempt),
      payload: payload,
    );
  }

  static AiProxyRequest soulMateDraw({
    required String name,
    required String birthDate,
    String? gender,
    String? intention,
  }) {
    final fp = AiRequestFingerprint.soulMate(
      name: name,
      birthDate: birthDate,
      gender: gender,
      intention: intention,
    );
    return AiProxyRequest(
      operation: AiOperation.soulmateDraw,
      idempotencyKey: PaidRequestIdempotency.resolve(fp),
      payload: {
        'name': PromptSanitizer.sanitize(name),
        'birthDate': birthDate.trim(),
        if (gender != null && gender.trim().isNotEmpty) 'gender': gender.trim(),
        if (intention != null && intention.trim().isNotEmpty)
          'intention': PromptSanitizer.sanitize(intention),
        ..._language,
      },
    );
  }

  static AiProxyRequest soulMateInterpretation({
    required String name,
    required String birthDate,
    String? gender,
    String? intention,
    Map<String, String>? identity,
    String? memorySummary,
  }) {
    final fp =
        'soulmate-text:${AiRequestFingerprint.soulMate(name: name, birthDate: birthDate, gender: gender, intention: intention)}|${identity?['nonce'] ?? ''}|${memorySummary ?? ''}';
    return AiProxyRequest(
      operation: AiOperation.soulmateInterpretation,
      idempotencyKey: PaidRequestIdempotency.resolve(fp),
      payload: {
        'name': PromptSanitizer.sanitize(name),
        'birthDate': birthDate.trim(),
        if (gender != null && gender.trim().isNotEmpty) 'gender': gender.trim(),
        if (intention != null && intention.trim().isNotEmpty)
          'intention': PromptSanitizer.sanitize(intention),
        if (identity != null && identity.isNotEmpty) 'identity': identity,
        if (memorySummary != null && memorySummary.trim().isNotEmpty)
          'memorySummary': PromptSanitizer.sanitize(memorySummary),
        ..._language,
      },
    );
  }

  static Map<String, String> get _language => {'language': OraclyL10n.code};
}
