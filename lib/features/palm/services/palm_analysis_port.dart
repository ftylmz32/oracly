/// Swappable palm analysis — real vision only, never fake CV.
library;

import '../../coffee/models/coffee_image_pick.dart';
import '../models/palm_analysis_error.dart';
import '../models/palm_hand.dart';
import '../models/palm_reading.dart';

class PalmAnalysisException implements Exception {
  const PalmAnalysisException(this.error);

  final PalmAnalysisError error;

  String get message => error.message;

  @override
  String toString() => 'PalmAnalysisException(${error.kind}: $message)';
}

abstract class PalmAnalysisPort {
  bool get isAvailable;

  Future<PalmReading> analyze(CoffeeImagePick image, {required PalmHand hand});
}

/// Optional capability: resume an already-staged operation using ONLY
/// the server-held image — never local bytes. Implemented by the real
/// vision adapter only; callers check `is PalmStagedAnalysisPort` before
/// use, so test doubles that never exercise recovery need not implement
/// it.
abstract class PalmStagedAnalysisPort {
  Future<PalmReading> analyzeStaged({
    required String operationId,
    required String mimeType,
    required PalmHand hand,
  });
}

abstract class PalmCompletedAnalysisPort {
  PalmReading restoreCompleted({
    required String resultId,
    required DateTime persistedAt,
    required PalmHand hand,
    required Map<String, dynamic> result,
  });
}
