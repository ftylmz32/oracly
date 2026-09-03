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

  Future<AiOutcome<CoffeeAiAnalysis>> coffee({
    required List<int> imageBytes,
    required String mimeType,
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
