/// Fact/theme ref validation against the Narrative request.
library;

import '../request/yildizname_narrative_request.dart';
import '../result/yildizname_narrative_structured_result.dart';
import '../result/yildizname_result_error.dart';

abstract final class YildiznameQualityRefs {
  YildiznameQualityRefs._();

  static void validate(
    YildiznameNarrativeRequest request,
    YildiznameNarrativeStructuredResult result,
  ) {
    final facts = request.factRefs;
    final themes = request.themeRefs;
    for (final ref in result.allFactRefs) {
      if (!facts.contains(ref)) {
        throw YildiznameResultException(
          YildiznameResultErrorKind.factRef,
          ref,
        );
      }
    }
    for (final ref in result.allThemeRefs) {
      if (!themes.contains(ref)) {
        throw YildiznameResultException(
          YildiznameResultErrorKind.themeRef,
          ref,
        );
      }
    }
    if (themes.isEmpty) {
      for (final ref in result.allThemeRefs) {
        throw YildiznameResultException(
          YildiznameResultErrorKind.themeRef,
          'emptyThemes:$ref',
        );
      }
    }
  }
}
