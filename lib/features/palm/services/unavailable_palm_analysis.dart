/// Default analysis port when no vision backend is configured.
library;

import '../../coffee/models/coffee_image_pick.dart';
import '../copy/palm_copy.dart';
import '../models/palm_analysis_error.dart';
import '../models/palm_hand.dart';
import '../models/palm_reading.dart';
import 'palm_analysis_port.dart';

class UnavailablePalmAnalysis implements PalmAnalysisPort {
  const UnavailablePalmAnalysis();

  @override
  bool get isAvailable => false;

  @override
  Future<PalmReading> analyze(CoffeeImagePick image, {required PalmHand hand}) {
    throw PalmAnalysisException(
      PalmAnalysisError(
        PalmAnalysisErrorKind.unavailable,
        PalmCopy.analysisUnavailable,
      ),
    );
  }
}
