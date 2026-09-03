/// Coffee vision adapter — real image through [OraclyAiService] only.
library;

import 'dart:io';

import '../../../core/logging/analysis_debug_log.dart';
import '../../ai/production/oracly_ai_service.dart';
import '../copy/coffee_copy.dart';
import '../models/coffee_image_pick.dart';
import '../models/coffee_reading.dart';
import 'coffee_analysis_port.dart';
import 'coffee_fortune_composer.dart';

class OpenAiCoffeeAnalysis implements CoffeeAnalysisPort {
  OpenAiCoffeeAnalysis({required this._ai});

  final OraclyAiService _ai;

  @override
  bool get isAvailable => _ai.visionAvailable;

  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) async {
    if (!_ai.visionAvailable) {
      throw CoffeeAnalysisException(CoffeeCopy.analysisUnavailable);
    }
    final bytes = await File(image.path).readAsBytes();
    final mime = image.mimeType ?? 'image/jpeg';
    final outcome = await _ai.analyzeCoffee(
      imageBytes: bytes,
      mimeType: mime,
    );
    return outcome.when(
      success: (analysis) => CoffeeFortuneComposer.compose(
        analysis.toReading(
          id: 'coffee_${DateTime.now().millisecondsSinceEpoch}',
          createdAt: DateTime.now(),
          imagePath: image.path,
        ),
      ),
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
}
