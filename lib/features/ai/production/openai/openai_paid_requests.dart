/// Paid-op proxy payloads — binder Idempotency-Key when a charge is in flight.
library;

import 'dart:convert';

import '../../services/prompt_sanitizer.dart';
import '../../../../core/l10n/l10n.dart';
import '../ai_request_fingerprint.dart';
import '../contexts/reading_ai_context.dart';
import '../transport/ai_operation.dart';
import '../transport/ai_proxy_request.dart';
import 'paid_request_idempotency.dart';

abstract final class OpenAiPaidRequests {
  OpenAiPaidRequests._();

  static AiProxyRequest dream({
    required String model,
    required DreamAiContext context,
  }) {
    final fp = AiRequestFingerprint.text('dream', context.narrative);
    return AiProxyRequest(
      operation: AiOperation.dreamAnalysis,
      model: model,
      idempotencyKey: PaidRequestIdempotency.resolve(fp),
      payload: {
        'narrative': PromptSanitizer.sanitize(context.narrative),
        'symbols': context.symbols,
        'emotions': context.emotions,
        ..._language,
      },
    );
  }

  static AiProxyRequest coffee({
    required String model,
    required List<int> imageBytes,
    required String mimeType,
  }) {
    final fp = AiRequestFingerprint.image('coffee', imageBytes);
    return AiProxyRequest(
      operation: AiOperation.coffeeAnalysis,
      model: model,
      idempotencyKey: PaidRequestIdempotency.resolve(fp),
      payload: {
        'mimeType': mimeType.trim().toLowerCase(),
        'imageBase64': base64Encode(imageBytes),
        'byteLength': imageBytes.length,
        ..._language,
      },
    );
  }

  static AiProxyRequest palm({
    required String model,
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
  }) {
    final fp = AiRequestFingerprint.image('palm', imageBytes, hand);
    return AiProxyRequest(
      operation: AiOperation.palmAnalysis,
      model: model,
      idempotencyKey: PaidRequestIdempotency.resolve(fp),
      payload: {
        'mimeType': mimeType.trim().toLowerCase(),
        'imageBase64': base64Encode(imageBytes),
        'byteLength': imageBytes.length,
        'hand': hand,
        ..._language,
      },
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

  static Map<String, String> get _language => {
        'language': OraclyL10n.code,
      };
}
