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
