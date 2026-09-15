/// Coffee vision adapter — real image through [OraclyAiService] only.
library;

import 'dart:io';

import '../../../core/copy/home_greeting_name.dart';
import '../../../core/logging/analysis_debug_log.dart';
import '../../ai/production/oracly_ai_service.dart';
import '../copy/coffee_copy.dart';
import '../models/coffee_image_pick.dart';
import '../models/coffee_reading.dart';
import 'coffee_analysis_port.dart';
import 'coffee_fortune_composer.dart';
import '../../ai/production/ai_outcome.dart';
import '../../ai/production/openai/openai_service_results.dart';

class OpenAiCoffeeAnalysis
    implements CoffeeAnalysisPort, CoffeeStagedAnalysisPort, CoffeeCompletedAnalysisPort {
  // Public param names stay readable (firstName/relevantThemes) while the
  // fields stay private — an initializing formal would require the param
  // itself to be named `_firstName`/`_relevantThemes`, which callers in
  // other libraries could not then pass by name.
  OpenAiCoffeeAnalysis({
    required this._ai,
    String? Function()? firstName,
    List<String> Function()? relevantThemes,
    String? Function(List<String> relevantThemes)? memorySummary,
    // ignore: prefer_initializing_formals
  })  : _firstName = firstName,
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
  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    if (!_ai.visionAvailable) {
      throw CoffeeAnalysisException(CoffeeCopy.analysisUnavailable);
    }
    final bytes = await File(image.path).readAsBytes();
    final mime = image.mimeType ?? 'image/jpeg';
    final ai = _ai;
    final OraclyEvidenceMemoryAiService? evidenceAi =
        ai is OraclyEvidenceMemoryAiService
            ? ai as OraclyEvidenceMemoryAiService
            : null;
    final outcome = evidenceAi != null && _memorySummary != null && _relevantThemes == null
        ? await evidenceAi.analyzeCoffeeWithEvidenceMemory(
            imageBytes: bytes,
            mimeType: mime,
            basePersonalization: _basePersonalization(),
            memorySummary: _memorySummary,
          )
        : await ai.analyzeCoffee(
            imageBytes: bytes,
            mimeType: mime,
            personalization: _personalization(),
          );
    return outcome.when(
      success: (analysis) {
        final composed = CoffeeFortuneComposer.compose(
          analysis.toReading(
            id: 'coffee_${DateTime.now().millisecondsSinceEpoch}',
            createdAt: DateTime.now(),
            imagePath: image.path,
          ),
        );
        if (composed == null) {
          // The backend interpretation failed this composer's own
          // trust/quality bar (BATCH 3A.2) — a real failure, never
          // silently downgraded into a fake reading via a legacy
          // template. Honest retry/error state, same as any other
          // analysis failure.
          logAnalysisFailure(
            feature: 'CoffeeAnalysis',
            stage: 'compose',
            error: 'authoritative_overall_rejected',
          );
          throw CoffeeAnalysisException(CoffeeCopy.analysisFailed);
        }
        return composed;
      },
      error: (failure) {
        logAnalysisFailure(
          feature: 'CoffeeAnalysis',
          stage: 'analyze',
          error: failure,
          kind: failure.kind.name,
        );
        throw CoffeeAnalysisException(failure.userMessage);
      },
    );
  }

  /// Resumes an already-staged operation using ONLY the server-held
  /// image — no local file is read. `imagePath` on the returned reading
  /// stays null (see [CoffeeReading.imagePath]); there is no local copy
  /// to reference after a controller/app restart lost the original.
  @override
  Future<CoffeeReading> analyzeStaged({
    required String operationId,
    required String mimeType,
  }) async {
    final ai = _ai;
    if (!ai.visionAvailable || ai is! OraclyStagedImageAiService) {
      throw CoffeeAnalysisException(CoffeeCopy.analysisUnavailable);
    }
    final staged = ai as OraclyStagedImageAiService;
    final OraclyEvidenceMemoryAiService? evidenceAi =
        ai is OraclyEvidenceMemoryAiService
            ? ai as OraclyEvidenceMemoryAiService
            : null;
    final outcome = evidenceAi != null && _memorySummary != null && _relevantThemes == null
        ? await evidenceAi.analyzeCoffeeStagedWithEvidenceMemory(
            operationId: operationId,
            mimeType: mimeType,
            basePersonalization: _basePersonalization(),
            memorySummary: _memorySummary,
          )
        : await staged.analyzeCoffeeStaged(
            operationId: operationId,
            mimeType: mimeType,
            personalization: _personalization(),
          );
    return outcome.when(
      success: (analysis) {
        final composed = CoffeeFortuneComposer.compose(
          analysis.toReading(
            id: 'coffee_${DateTime.now().millisecondsSinceEpoch}',
            createdAt: DateTime.now(),
            imagePath: null,
          ),
        );
        if (composed == null) {
          logAnalysisFailure(
            feature: 'CoffeeAnalysis',
            stage: 'compose_staged',
            error: 'authoritative_overall_rejected',
          );
          throw CoffeeAnalysisException(CoffeeCopy.analysisFailed);
        }
        return composed;
      },
      error: (failure) {
        logAnalysisFailure(
          feature: 'CoffeeAnalysis',
          stage: 'analyze_staged',
          error: failure,
          kind: failure.kind.name,
        );
        throw CoffeeAnalysisException(failure.userMessage);
      },
    );
  }

  @override
  CoffeeReading restoreCompleted({
    required String resultId,
    required DateTime persistedAt,
    required Map<String, dynamic> result,
  }) {
    return OpenAiServiceResults.coffee(AiOutcome.success(result)).when(
      success: (analysis) {
        final reading = CoffeeFortuneComposer.compose(
          analysis.toReading(
            id: resultId,
            createdAt: persistedAt,
            imagePath: null,
          ),
        );
        if (reading == null) throw CoffeeAnalysisException(CoffeeCopy.analysisFailed);
        return reading;
      },
      error: (failure) => throw CoffeeAnalysisException(failure.userMessage),
    );
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
