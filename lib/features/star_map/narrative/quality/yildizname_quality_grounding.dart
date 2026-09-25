/// Deterministic planet–sign / house / aspect grounding checks.
library;

import '../request/yildizname_narrative_request.dart';
import '../result/yildizname_narrative_structured_result.dart';
import 'yildizname_quality_aspect_grounding.dart';
import 'yildizname_quality_body_grounding.dart';

abstract final class YildiznameQualityGrounding {
  YildiznameQualityGrounding._();

  static void validate(
    YildiznameNarrativeRequest request,
    YildiznameNarrativeStructuredResult result,
  ) {
    final prose = result.visibleProse.toLowerCase();
    YildiznameQualityBodyGrounding.validate(request, prose);
    YildiznameQualityAspectGrounding.validateHouses(request, prose);
    YildiznameQualityAspectGrounding.validateAspects(request, prose);
  }
}
