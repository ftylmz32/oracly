/// Shared coffee/palm vision calls through the proxy transport.
library;

import '../ai_failure.dart';
import '../ai_outcome.dart';
import '../ai_request_abuse_policy.dart';
import '../ai_request_fingerprint.dart';
import '../ai_request_guard.dart';
import '../ai_runtime_config.dart';
import '../models/coffee_ai_analysis.dart';
import '../models/palm_ai_analysis.dart';
import '../transport/ai_transport.dart';
import '../transport/coffee_image_limits.dart';
import 'openai_paid_requests.dart';
import 'openai_service_results.dart';

class OpenAiImageAnalysis {
  OpenAiImageAnalysis({
    required this._config,
    required this._transport,
    required this._guard,
  });

  final AiRuntimeConfig _config;
  final AiTransport _transport;
  final AiRequestGuard _guard;

  Future<AiOutcome<CoffeeAiAnalysis>> coffeeWithEvidenceMemory({
    required List<int> imageBytes,
    required String mimeType,
    required Map<String, dynamic>? basePersonalization,
    required String? Function(List<String>) memorySummary,
  }) {
    final blocked = _blocked(imageBytes, mimeType, feature: AiAnalysisFeature.coffee);
    if (blocked != null) return Future.value(blocked);
    final mime = CoffeeImageLimits.resolveMime(bytes: imageBytes, claimedMime: mimeType);
    final fingerprint = AiRequestFingerprint.image('coffee', imageBytes);
    return _guard.runOutcome('coffee', kind: AiRequestKind.coffee, fingerprint: fingerprint, () async {
      final bridge = OpenAiPaidRequests.coffee(
        model: _config.model,
        imageBytes: imageBytes,
        mimeType: mime,
      ).idempotencyKey!;
      final observed = await _transport.execute(OpenAiPaidRequests.coffee(
        model: _config.model,
        imageBytes: imageBytes,
        mimeType: mime,
        readingPhase: 'observe',
        readingBridgeKey: bridge,
      ));
      return observed.when(
        success: (data) => _finishCoffeeMemory(
          data, imageBytes, mime, bridge, basePersonalization, memorySummary,
        ),
        error: (failure) async => AiOutcome.failure(failure),
      );
    });
  }

  Future<AiOutcome<CoffeeAiAnalysis>> _finishCoffeeMemory(
    Map<String, dynamic> observed,
    List<int> bytes,
    String mime,
    String bridge,
    Map<String, dynamic>? base,
    String? Function(List<String>) retrieve,
  ) async {
    final personalization = _evidencePersonalization(observed, base, retrieve);
    return OpenAiServiceResults.coffee(await _transport.execute(OpenAiPaidRequests.coffee(
      model: _config.model,
      imageBytes: bytes,
      mimeType: mime,
      personalization: personalization,
      readingPhase: 'write',
      readingBridgeKey: bridge,
      observationToken: observed['observationToken'] as String?,
    )));
  }

  Future<AiOutcome<PalmAiAnalysis>> palmWithEvidenceMemory({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
    required Map<String, dynamic>? basePersonalization,
    required String? Function(List<String>) memorySummary,
  }) {
    final blocked = _blocked(imageBytes, mimeType, feature: AiAnalysisFeature.palm);
    if (blocked != null) return Future.value(blocked);
    final mime = CoffeeImageLimits.resolveMime(bytes: imageBytes, claimedMime: mimeType);
    final fingerprint = AiRequestFingerprint.image('palm', imageBytes, hand);
    return _guard.runOutcome('palm', kind: AiRequestKind.palm, fingerprint: fingerprint, () async {
      final bridge = OpenAiPaidRequests.palm(
        model: _config.model, imageBytes: imageBytes, mimeType: mime, hand: hand,
      ).idempotencyKey!;
      final observed = await _transport.execute(OpenAiPaidRequests.palm(
        model: _config.model,
        imageBytes: imageBytes,
        mimeType: mime,
        hand: hand,
        readingPhase: 'observe',
        readingBridgeKey: bridge,
      ));
      return observed.when(
        success: (data) => _finishPalmMemory(
          data, imageBytes, mime, hand, bridge, basePersonalization, memorySummary,
        ),
        error: (failure) async => AiOutcome.failure(failure),
      );
    });
  }

  Future<AiOutcome<PalmAiAnalysis>> _finishPalmMemory(
    Map<String, dynamic> observed,
    List<int> bytes,
    String mime,
    String hand,
    String bridge,
    Map<String, dynamic>? base,
    String? Function(List<String>) retrieve,
  ) async {
    final personalization = _evidencePersonalization(observed, base, retrieve);
    return OpenAiServiceResults.palm(await _transport.execute(OpenAiPaidRequests.palm(
      model: _config.model,
      imageBytes: bytes,
      mimeType: mime,
      hand: hand,
      personalization: personalization,
      readingPhase: 'write',
      readingBridgeKey: bridge,
      observationToken: observed['observationToken'] as String?,
    )));
  }

  Map<String, dynamic>? _evidencePersonalization(
    Map<String, dynamic> observed,
    Map<String, dynamic>? base,
    String? Function(List<String>) retrieve,
  ) {
    final raw = observed['relevantThemes'];
    final themes = raw is List
        ? raw.whereType<String>().map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).take(3).toList()
        : <String>[];
    String? memory;
    if (themes.isNotEmpty) {
      try {
        memory = retrieve(themes)?.trim();
      } catch (_) {}
    }
    final result = <String, dynamic>{...?base};
    if (themes.isNotEmpty) result['relevantThemes'] = themes;
    if (memory != null && memory.isNotEmpty) result['memorySummary'] = memory;
    return result.isEmpty ? null : result;
  }

  Future<AiOutcome<CoffeeAiAnalysis>> coffeeStagedWithEvidenceMemory({
    required String operationId,
    required String mimeType,
    required Map<String, dynamic>? basePersonalization,
    required String? Function(List<String>) memorySummary,
  }) {
    if (!_config.visionAvailable) {
      return Future.value(AiOutcome.failure(
        AiFailure.imageAnalysisUnavailable(feature: AiAnalysisFeature.coffee),
      ));
    }
    final fingerprint = AiRequestFingerprint.text('coffee_staged', operationId);
    return _guard.runOutcome('coffee', kind: AiRequestKind.coffee, fingerprint: fingerprint, () async {
      final bridge = OpenAiPaidRequests.coffeeStaged(
        model: _config.model, operationId: operationId, mimeType: mimeType,
      ).idempotencyKey!;
      final observed = await _transport.execute(OpenAiPaidRequests.coffeeStaged(
        model: _config.model, operationId: operationId, mimeType: mimeType,
        readingPhase: 'observe', readingBridgeKey: bridge,
      ));
      return observed.when(success: (data) async {
        final personalization = _evidencePersonalization(data, basePersonalization, memorySummary);
        return OpenAiServiceResults.coffee(await _transport.execute(OpenAiPaidRequests.coffeeStaged(
          model: _config.model, operationId: operationId, mimeType: mimeType,
          personalization: personalization, readingPhase: 'write', readingBridgeKey: bridge,
          observationToken: data['observationToken'] as String?,
        )));
      }, error: (failure) async => AiOutcome.failure(failure));
    });
  }

  Future<AiOutcome<PalmAiAnalysis>> palmStagedWithEvidenceMemory({
    required String operationId,
    required String mimeType,
    required String hand,
    required Map<String, dynamic>? basePersonalization,
    required String? Function(List<String>) memorySummary,
  }) {
    if (!_config.visionAvailable) {
      return Future.value(AiOutcome.failure(
        AiFailure.imageAnalysisUnavailable(feature: AiAnalysisFeature.palm),
      ));
    }
    final fingerprint = AiRequestFingerprint.text('palm_staged', '$operationId|$hand');
    return _guard.runOutcome('palm', kind: AiRequestKind.palm, fingerprint: fingerprint, () async {
      final bridge = OpenAiPaidRequests.palmStaged(
        model: _config.model, operationId: operationId, mimeType: mimeType, hand: hand,
      ).idempotencyKey!;
      final observed = await _transport.execute(OpenAiPaidRequests.palmStaged(
        model: _config.model, operationId: operationId, mimeType: mimeType, hand: hand,
        readingPhase: 'observe', readingBridgeKey: bridge,
      ));
      return observed.when(success: (data) async {
        final personalization = _evidencePersonalization(data, basePersonalization, memorySummary);
        return OpenAiServiceResults.palm(await _transport.execute(OpenAiPaidRequests.palmStaged(
          model: _config.model, operationId: operationId, mimeType: mimeType, hand: hand,
          personalization: personalization, readingPhase: 'write', readingBridgeKey: bridge,
          observationToken: data['observationToken'] as String?,
        )));
      }, error: (failure) async => AiOutcome.failure(failure));
    });
  }

  Future<AiOutcome<CoffeeAiAnalysis>> coffee({
    required List<int> imageBytes,
    required String mimeType,
    Map<String, dynamic>? personalization,
  }) {
    final blocked = _blocked(
      imageBytes,
      mimeType,
      feature: AiAnalysisFeature.coffee,
    );
    if (blocked != null) return Future.value(blocked);
    final mime = CoffeeImageLimits.resolveMime(
      bytes: imageBytes,
      claimedMime: mimeType,
    );
    return _guard.runOutcome(
      'coffee',
      kind: AiRequestKind.coffee,
      fingerprint: AiRequestFingerprint.image('coffee', imageBytes),
      () async {
        return OpenAiServiceResults.coffee(
          await _transport.execute(
            OpenAiPaidRequests.coffee(
              model: _config.model,
              imageBytes: imageBytes,
              mimeType: mime,
              personalization: personalization,
            ),
          ),
        );
      },
    );
  }

  Future<AiOutcome<PalmAiAnalysis>> palm({
    required List<int> imageBytes,
    required String mimeType,
    required String hand,
    Map<String, dynamic>? personalization,
  }) {
    final blocked = _blocked(
      imageBytes,
      mimeType,
      feature: AiAnalysisFeature.palm,
    );
    if (blocked != null) return Future.value(blocked);
    final mime = CoffeeImageLimits.resolveMime(
      bytes: imageBytes,
      claimedMime: mimeType,
    );
    return _guard.runOutcome(
      'palm',
      kind: AiRequestKind.palm,
      fingerprint: AiRequestFingerprint.image('palm', imageBytes, hand),
      () async {
        return OpenAiServiceResults.palm(
          await _transport.execute(
            OpenAiPaidRequests.palm(
              model: _config.model,
              imageBytes: imageBytes,
              mimeType: mime,
              hand: hand,
              personalization: personalization,
            ),
          ),
        );
      },
    );
  }

  /// Resumes an already-staged Coffee operation — server-held image only,
  /// no local bytes to validate/sniff/fingerprint. Skips the byte-shaped
  /// pre-checks in [_blocked] (already enforced server-side at staging
  /// time) and derives the dedup fingerprint from `operationId`.
  Future<AiOutcome<CoffeeAiAnalysis>> coffeeStaged({
    required String operationId,
    required String mimeType,
    Map<String, dynamic>? personalization,
  }) {
    if (!_config.visionAvailable) {
      return Future.value(
        AiOutcome.failure(
          AiFailure.imageAnalysisUnavailable(feature: AiAnalysisFeature.coffee),
        ),
      );
    }
    return _guard.runOutcome(
      'coffee',
      kind: AiRequestKind.coffee,
      fingerprint: AiRequestFingerprint.text('coffee_staged', operationId),
      () async {
        return OpenAiServiceResults.coffee(
          await _transport.execute(
            OpenAiPaidRequests.coffeeStaged(
              model: _config.model,
              operationId: operationId,
              mimeType: mimeType,
              personalization: personalization,
            ),
          ),
        );
      },
    );
  }

  /// Resumes an already-staged Palm operation — see [coffeeStaged].
  Future<AiOutcome<PalmAiAnalysis>> palmStaged({
    required String operationId,
    required String mimeType,
    required String hand,
    Map<String, dynamic>? personalization,
  }) {
    if (!_config.visionAvailable) {
      return Future.value(
        AiOutcome.failure(
          AiFailure.imageAnalysisUnavailable(feature: AiAnalysisFeature.palm),
        ),
      );
    }
    return _guard.runOutcome(
      'palm',
      kind: AiRequestKind.palm,
      fingerprint: AiRequestFingerprint.text('palm_staged', '$operationId|$hand'),
      () async {
        return OpenAiServiceResults.palm(
          await _transport.execute(
            OpenAiPaidRequests.palmStaged(
              model: _config.model,
              operationId: operationId,
              mimeType: mimeType,
              hand: hand,
              personalization: personalization,
            ),
          ),
        );
      },
    );
  }

  AiOutcome<Never>? _blocked(
    List<int> imageBytes,
    String mimeType, {
    required AiAnalysisFeature feature,
  }) {
    if (!_config.visionAvailable) {
      return AiOutcome.failure(
        AiFailure.imageAnalysisUnavailable(feature: feature),
      );
    }
    final invalid = CoffeeImageLimits.validate(
      bytes: imageBytes,
      mimeType: mimeType,
    );
    if (invalid != null) return AiOutcome.failure(invalid);
    return null;
  }
}
