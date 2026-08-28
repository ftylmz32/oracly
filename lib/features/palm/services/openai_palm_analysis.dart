/// Palm vision adapter — real image through [OraclyAiService] only.
library;

import 'dart:io';

import '../../ai/production/ai_failure.dart';
import '../../ai/production/oracly_ai_service.dart';
import '../../ai/production/transport/coffee_image_limits.dart';
import '../../coffee/models/coffee_image_pick.dart';
import '../copy/palm_copy.dart';
import '../models/palm_analysis_error.dart';
import '../models/palm_hand.dart';
import '../models/palm_reading.dart';
import 'palm_analysis_port.dart';
import 'palm_fortune_composer.dart';

class OpenAiPalmAnalysis implements PalmAnalysisPort {
  OpenAiPalmAnalysis({required this._ai});

  final OraclyAiService _ai;

  @override
  bool get isAvailable => _ai.visionAvailable;

  @override
  Future<PalmReading> analyze(
    CoffeeImagePick image, {
    required PalmHand hand,
  }) async {
    if (!_ai.visionAvailable) {
      throw PalmAnalysisException(
        PalmAnalysisError(
          PalmAnalysisErrorKind.unavailable,
          PalmCopy.analysisUnavailable,
        ),
      );
    }
    final bytes = await File(image.path).readAsBytes();
    if (CoffeeImageLimits.looksLikeHeic(bytes)) {
      throw PalmAnalysisException(
        PalmAnalysisError(
          PalmAnalysisErrorKind.unsupportedImage,
          PalmCopy.imageUnsupported,
        ),
      );
    }
    // Intake normalizes to JPEG before this adapter runs.
    const mime = 'image/jpeg';
    final outcome = await _ai.analyzePalm(
      imageBytes: bytes,
      mimeType: mime,
      hand: hand.name,
    );
    return outcome.when(
      success: (analysis) => PalmFortuneComposer.compose(
        analysis.toReading(
          id: 'palm_${DateTime.now().millisecondsSinceEpoch}',
          createdAt: DateTime.now(),
          hand: hand,
          imagePath: image.path,
        ),
      ),
      error: (failure) => throw PalmAnalysisException(_mapFailure(failure)),
    );
  }

  static PalmAnalysisError _mapFailure(AiFailure failure) {
    final kind = switch (failure.kind) {
      AiFailureKind.network => PalmAnalysisErrorKind.network,
      AiFailureKind.timeout => PalmAnalysisErrorKind.timeout,
      AiFailureKind.invalidResponse => PalmAnalysisErrorKind.invalidResponse,
      AiFailureKind.imageAnalysisUnavailable ||
      AiFailureKind.noConfiguration ||
      AiFailureKind.unauthorized =>
        PalmAnalysisErrorKind.unavailable,
      AiFailureKind.rateLimit ||
      AiFailureKind.providerError =>
        PalmAnalysisErrorKind.unknown,
    };
    return PalmAnalysisError(kind, failure.userMessage);
  }
}
