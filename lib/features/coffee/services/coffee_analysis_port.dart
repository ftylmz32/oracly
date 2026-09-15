/// Swappable coffee-cup analysis — real vision only, never fake CV.
library;

import '../models/coffee_image_pick.dart';
import '../models/coffee_reading.dart';

class CoffeeAnalysisException implements Exception {
  const CoffeeAnalysisException(this.message);
  final String message;
}

abstract class CoffeeAnalysisPort {
  bool get isAvailable;

  Future<CoffeeReading> analyze(CoffeeImagePick image);
}

/// Optional capability: resume an already-staged operation using ONLY
/// the server-held image — never local bytes. Implemented by the real
/// vision adapter only; callers check `is CoffeeStagedAnalysisPort`
/// before use, so test doubles that never exercise recovery need not
/// implement it.
abstract class CoffeeStagedAnalysisPort {
  Future<CoffeeReading> analyzeStaged({
    required String operationId,
    required String mimeType,
  });
}

abstract class CoffeeCompletedAnalysisPort {
  CoffeeReading restoreCompleted({
    required String resultId,
    required DateTime persistedAt,
    required Map<String, dynamic> result,
  });
}
