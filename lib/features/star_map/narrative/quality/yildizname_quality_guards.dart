/// Degree claims, unsupported astrology, and privacy sentinels.
library;

import '../request/yildizname_narrative_request.dart';
import '../result/yildizname_narrative_structured_result.dart';
import '../result/yildizname_result_error.dart';

abstract final class YildiznameQualityDegree {
  YildiznameQualityDegree._();

  static final _degree = RegExp(
    r'\b\d{1,3}\s*(?:°|derece|degrees?|градус)\b',
    caseSensitive: false,
  );

  static void validate(YildiznameNarrativeStructuredResult result) {
    if (_degree.hasMatch(result.visibleProse)) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.prose,
        'degreeClaim',
      );
    }
  }
}

abstract final class YildiznameQualityUnsupported {
  YildiznameQualityUnsupported._();

  static final patterns = <RegExp>[
    RegExp(r'\bnorth\s+node\b', caseSensitive: false),
    RegExp(r'\bsouth\s+node\b', caseSensitive: false),
    RegExp(r'\bkuzey\s+düğüm', caseSensitive: false),
    RegExp(r'\bgüney\s+düğüm', caseSensitive: false),
    RegExp(r'\bchiron\b', caseSensitive: false),
    RegExp(r'\blilith\b', caseSensitive: false),
    RegExp(r'\bpart of fortune\b', caseSensitive: false),
    RegExp(r'\bfortuna\b', caseSensitive: false),
    RegExp(r'\bstellium\b', caseSensitive: false),
    RegExp(r'\bgrand\s+trine\b', caseSensitive: false),
    RegExp(r'\bbüyük\s+üçgen\b', caseSensitive: false),
    RegExp(r'\bt[-\s]?square\b', caseSensitive: false),
    RegExp(r'\byod\b', caseSensitive: false),
    RegExp(r'\bchart\s+ruler\b', caseSensitive: false),
    RegExp(r'\bharita\s+yönetic', caseSensitive: false),
  ];

  static void validate(YildiznameNarrativeStructuredResult result) {
    final prose = result.visibleProse;
    for (final re in patterns) {
      if (re.hasMatch(prose)) {
        throw YildiznameResultException(
          YildiznameResultErrorKind.quality,
          re.pattern,
        );
      }
    }
  }
}

abstract final class YildiznameQualityPrivacy {
  YildiznameQualityPrivacy._();

  static final leaks = <RegExp>[
    RegExp(r'\bownerId\b', caseSensitive: false),
    RegExp(r'\bfirebase\b', caseSensitive: false),
    RegExp(r'\blatitude\b', caseSensitive: false),
    RegExp(r'\blongitude\b', caseSensitive: false),
    RegExp(r'\btimezoneId\b', caseSensitive: false),
    RegExp(r'\bevidenceFingerprint\b', caseSensitive: false),
    RegExp(r'\butcInstantIso\b', caseSensitive: false),
  ];

  static void validate(
    YildiznameNarrativeRequest request,
    YildiznameNarrativeStructuredResult result,
  ) {
    final prose = result.visibleProse;
    for (final re in leaks) {
      if (re.hasMatch(prose)) {
        throw YildiznameResultException(
          YildiznameResultErrorKind.privacy,
          re.pattern,
        );
      }
    }
  }
}
