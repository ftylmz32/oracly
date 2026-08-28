/// Default analysis port when no vision backend is configured.
library;

import '../copy/coffee_copy.dart';
import '../models/coffee_image_pick.dart';
import '../models/coffee_reading.dart';
import 'coffee_analysis_port.dart';

class UnavailableCoffeeAnalysis implements CoffeeAnalysisPort {
  const UnavailableCoffeeAnalysis();

  @override
  bool get isAvailable => false;

  @override
  Future<CoffeeReading> analyze(CoffeeImagePick image) {
    throw CoffeeAnalysisException(CoffeeCopy.analysisUnavailable);
  }
}
