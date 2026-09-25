/// Scope honesty — legacy/reduced cannot claim Asc/MC/houses/aspects.
library;

import '../request/yildizname_narrative_request.dart';
import '../request/yildizname_narrative_scope.dart';
import '../result/yildizname_narrative_structured_result.dart';
import '../result/yildizname_result_error.dart';
import '../result/yildizname_section_kind.dart';

abstract final class YildiznameQualityScope {
  YildiznameQualityScope._();

  static void validate(
    YildiznameNarrativeRequest request,
    YildiznameNarrativeStructuredResult result,
  ) {
    if (result.scope != request.scope) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.scope,
        'mismatch',
      );
    }
    if (result.languageCode != request.languageCode) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.locale,
        'mismatch',
      );
    }
    if (request.scope != YildiznameNarrativeScope.full) {
      for (final s in result.sections) {
        if (s.kind == YildiznameSectionKind.anglesAndHouses) {
          throw YildiznameResultException(
            YildiznameResultErrorKind.scopeHonesty,
            'angles_and_houses',
          );
        }
      }
      for (final ref in result.allFactRefs) {
        if (ref.startsWith('angle.') ||
            ref.startsWith('house.') ||
            ref.startsWith('aspect.')) {
          throw YildiznameResultException(
            YildiznameResultErrorKind.scopeHonesty,
            ref,
          );
        }
      }
    }
  }
}
