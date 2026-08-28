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
