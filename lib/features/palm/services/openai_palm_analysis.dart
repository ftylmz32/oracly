/// Palm vision adapter — real image through [OraclyAiService] only.
library;

import 'dart:io';

import '../../../core/copy/home_greeting_name.dart';
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
import '../../ai/production/ai_outcome.dart';
import '../../ai/production/openai/openai_service_results.dart';

class OpenAiPalmAnalysis implements PalmAnalysisPort, PalmStagedAnalysisPort, PalmCompletedAnalysisPort {
  // Public param names stay readable (firstName/relevantThemes) while the
  // fields stay private — an initializing formal would require the param
  // itself to be named `_firstName`/`_relevantThemes`, which callers in
  // other libraries could not then pass by name.
  OpenAiPalmAnalysis({
    required this._ai,
    String? Function()? firstName,
    List<String> Function()? relevantThemes,
    String? Function(List<String> relevantThemes)? memorySummary,
    // ignore: prefer_initializing_formals
  }) : _firstName = firstName,
       // ignore: prefer_initializing_formals
       _relevantThemes = relevantThemes,
       _memorySummary = memorySummary;

  final OraclyAiService _ai;
  final String? Function()? _firstName;
  final List<String> Function()? _relevantThemes;
  final String? Function(List<String> relevantThemes)? _memorySummary;

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
    final ai = _ai;
    final OraclyEvidenceMemoryAiService? evidenceAi =
        ai is OraclyEvidenceMemoryAiService
            ? ai as OraclyEvidenceMemoryAiService
            : null;
    final outcome = evidenceAi != null && _memorySummary != null && _relevantThemes == null
        ? await evidenceAi.analyzePalmWithEvidenceMemory(
            imageBytes: bytes,
            mimeType: mime,
            hand: hand.name,
            basePersonalization: _basePersonalization(),
            memorySummary: _memorySummary,
          )
        : await ai.analyzePalm(
            imageBytes: bytes,
            mimeType: mime,
            hand: hand.name,
            personalization: _personalization(),
          );
    return outcome.when(
      success: (analysis) {
        final composed = PalmFortuneComposer.compose(
          analysis.toReading(
            id: 'palm_${DateTime.now().millisecondsSinceEpoch}',
            createdAt: DateTime.now(),
            hand: hand,
            imagePath: image.path,
          ),
        );
        if (composed == null) {
          // The backend interpretation failed this composer's own
          // trust/quality bar (BATCH 3A.2) — a real failure, never
          // silently downgraded into a fake reading via a legacy
          // template. Honest retry/error state, same as any other
          // analysis failure.
          throw PalmAnalysisException(
            PalmAnalysisError(
              PalmAnalysisErrorKind.invalidResponse,
              PalmCopy.analysisFailed,
            ),
          );
        }
        return composed;
      },
      error: (failure) => throw PalmAnalysisException(_mapFailure(failure)),
    );
  }

  /// Resumes an already-staged operation using ONLY the server-held
  /// image — no local file is read. `imagePath` on the returned reading
  /// stays null; there is no local copy to reference after a
  /// controller/app restart lost the original.
  @override
  Future<PalmReading> analyzeStaged({
    required String operationId,
    required String mimeType,
    required PalmHand hand,
  }) async {
    final ai = _ai;
    if (!ai.visionAvailable || ai is! OraclyStagedImageAiService) {
      throw PalmAnalysisException(
        PalmAnalysisError(
          PalmAnalysisErrorKind.unavailable,
          PalmCopy.analysisUnavailable,
        ),
      );
    }
    final staged = ai as OraclyStagedImageAiService;
    final OraclyEvidenceMemoryAiService? evidenceAi =
        ai is OraclyEvidenceMemoryAiService
            ? ai as OraclyEvidenceMemoryAiService
            : null;
    final outcome = evidenceAi != null && _memorySummary != null && _relevantThemes == null
        ? await evidenceAi.analyzePalmStagedWithEvidenceMemory(
            operationId: operationId,
            mimeType: mimeType,
            hand: hand.name,
            basePersonalization: _basePersonalization(),
            memorySummary: _memorySummary,
          )
        : await staged.analyzePalmStaged(
            operationId: operationId,
            mimeType: mimeType,
            hand: hand.name,
            personalization: _personalization(),
          );
    return outcome.when(
      success: (analysis) {
        final composed = PalmFortuneComposer.compose(
          analysis.toReading(
            id: 'palm_${DateTime.now().millisecondsSinceEpoch}',
            createdAt: DateTime.now(),
            hand: hand,
            imagePath: null,
          ),
        );
        if (composed == null) {
          throw PalmAnalysisException(
            PalmAnalysisError(
              PalmAnalysisErrorKind.invalidResponse,
              PalmCopy.analysisFailed,
            ),
          );
        }
        return composed;
      },
      error: (failure) => throw PalmAnalysisException(_mapFailure(failure)),
    );
  }

  @override
  PalmReading restoreCompleted({
    required String resultId,
    required DateTime persistedAt,
    required PalmHand hand,
    required Map<String, dynamic> result,
  }) {
    return OpenAiServiceResults.palm(AiOutcome.success(result)).when(
      success: (analysis) {
        final reading = PalmFortuneComposer.compose(
          analysis.toReading(
            id: resultId,
            createdAt: persistedAt,
            hand: hand,
            imagePath: null,
          ),
        );
        if (reading == null) {
          throw PalmAnalysisException(PalmAnalysisError(
            PalmAnalysisErrorKind.invalidResponse,
            PalmCopy.analysisFailed,
          ));
        }
        return reading;
      },
      error: (failure) => throw PalmAnalysisException(_mapFailure(failure)),
    );
  }

  static PalmAnalysisError _mapFailure(AiFailure failure) {
    final kind = switch (failure.kind) {
      AiFailureKind.network => PalmAnalysisErrorKind.network,
      AiFailureKind.timeout => PalmAnalysisErrorKind.timeout,
      AiFailureKind.invalidResponse => PalmAnalysisErrorKind.invalidResponse,
      AiFailureKind.authPending => PalmAnalysisErrorKind.network,
      AiFailureKind.imageAnalysisUnavailable ||
      AiFailureKind.noConfiguration ||
      AiFailureKind.unauthorized ||
      AiFailureKind.appCheck => PalmAnalysisErrorKind.unavailable,
      AiFailureKind.rateLimit ||
      AiFailureKind.providerError ||
      AiFailureKind.localPersistence => PalmAnalysisErrorKind.unknown,
    };
    return PalmAnalysisError(kind, failure.userMessage);
  }

  /// Real context only — never invented. The live capture flow has no
  /// question and no relevance proof, so it must not pass discovery
  /// labels. `relevantThemes` is still forwarded when a future caller
  /// supplies themes already proven relevant to this reading. Intention
  /// and memory are never fabricated. Missing context never blocks.
  Map<String, dynamic>? _personalization() {
    final name = HomeGreetingName.firstNameOrNull(_firstName?.call());
    final themes = (_relevantThemes?.call() ?? const [])
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .take(3)
        .toList(growable: false);
    String? memory;
    if (themes.isNotEmpty) {
      try {
        memory = _memorySummary?.call(themes)?.trim();
      } catch (_) {
        // Memory enrichment is optional. Vision interpretation must continue.
      }
    }
    if (name == null && themes.isEmpty && (memory == null || memory.isEmpty)) {
      return null;
    }
    return {
      'firstName': ?name,
      if (themes.isNotEmpty) 'relevantThemes': themes,
      if (memory != null && memory.isNotEmpty) 'memorySummary': memory,
    };
  }

  Map<String, dynamic>? _basePersonalization() {
    final name = HomeGreetingName.firstNameOrNull(_firstName?.call());
    return name == null ? null : {'firstName': name};
  }
}
