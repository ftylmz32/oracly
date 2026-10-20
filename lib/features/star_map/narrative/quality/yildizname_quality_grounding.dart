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
    final prose = maskAddressName(
      result.visibleProse.toLowerCase(),
      request.addressName,
    );
    YildiznameQualityBodyGrounding.validate(request, prose);
    YildiznameQualityAspectGrounding.validateHouses(request, prose);
    YildiznameQualityAspectGrounding.validateAspects(request, prose);
  }

  /// A person named Başak, Aslan or Koç is not a sign claim. Only the ways a
  /// name addresses someone are neutralised: the vocative ("Başak, …") and
  /// the genitive ("Başak'ın"). "Güneş Başak burcunda" or "Başak'ta" stay
  /// visible to grounding, so a wrong sign claim is still caught.
  static String maskAddressName(String lowerProse, String? addressName) {
    final name = addressName?.trim().toLowerCase() ?? '';
    if (name.isEmpty) return lowerProse;
    final pattern = RegExp(
      r'(?<![\p{L}])' +
          RegExp.escape(name) +
          r"(?:['’]n?[ıiuü]n(?![\p{L}])|(?=\s*(?:[,.!?;:]|$)))",
      unicode: true,
    );
    return lowerProse.replaceAll(pattern, 'kişi');
  }
}
