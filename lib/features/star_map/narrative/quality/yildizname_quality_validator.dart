/// Ordered Yıldızname Narrative V1 quality validator.
library;

import '../request/yildizname_narrative_request.dart';
import '../result/yildizname_narrative_structured_result.dart';
import '../result/yildizname_result_error.dart';
import '../versions.dart';
import 'yildizname_quality_coverage.dart';
import 'yildizname_quality_grounding.dart';
import 'yildizname_quality_guards.dart';
import 'yildizname_quality_prose.dart';
import 'yildizname_quality_refs.dart';
import 'yildizname_quality_safety.dart';
import 'yildizname_quality_scope.dart';

/// Validation order:
/// contract → language/scope → fact refs → theme refs → scope honesty →
/// grounding → privacy → safety → prose → coverage/genericity → synthesis
abstract final class YildiznameQualityValidator {
  YildiznameQualityValidator._();

  /// Exposed for tests asserting order of first failure.
  static const stageOrder = <String>[
    'contract',
    'languageScope',
    'factRefs',
    'themeRefs',
    'scopeHonesty',
    'grounding',
    'privacy',
    'safety',
    'prose',
    'coverage',
  ];

  static void validate({
    required YildiznameNarrativeRequest request,
    required YildiznameNarrativeStructuredResult result,
  }) {
    if (result.contractVersion != kYildiznameResultContractVersion) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.version,
        '${result.contractVersion}',
      );
    }
    YildiznameQualityScope.validate(request, result);
    YildiznameQualityRefs.validate(request, result);
    YildiznameQualityGrounding.validate(request, result);
    YildiznameQualityPrivacy.validate(request, result);
    YildiznameQualitySafety.validate(result);
    YildiznameQualityDegree.validate(result);
    YildiznameQualityUnsupported.validate(result);
    YildiznameQualityProse.validate(request, result);
    YildiznameQualityCoverage.validate(request, result);
  }
}
