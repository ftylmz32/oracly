/// Coverage / synthesis requirements by Narrative scope.
library;

import '../request/yildizname_narrative_request.dart';
import '../request/yildizname_narrative_scope.dart';
import '../result/yildizname_narrative_structured_result.dart';
import '../result/yildizname_result_error.dart';

abstract final class YildiznameQualityCoverage {
  YildiznameQualityCoverage._();

  static const _personalSocial = {
    'placement.mercury',
    'placement.venus',
    'placement.mars',
    'placement.jupiter',
    'placement.saturn',
  };

  static void validate(
    YildiznameNarrativeRequest request,
    YildiznameNarrativeStructuredResult result,
  ) {
    final used = result.allFactRefs.toSet();
    switch (request.scope) {
      case YildiznameNarrativeScope.legacy:
        if (!used.contains('placement.sun')) {
          throw YildiznameResultException(
            YildiznameResultErrorKind.coverage,
            'legacySun',
          );
        }
      case YildiznameNarrativeScope.reduced:
        final placements = used.where((r) => r.startsWith('placement.'));
        if (placements.length < 2 && request.placements.length >= 2) {
          throw YildiznameResultException(
            YildiznameResultErrorKind.coverage,
            'reduced',
          );
        }
      case YildiznameNarrativeScope.full:
        _validateFull(request, used, result);
    }
  }

  static void _validateFull(
    YildiznameNarrativeRequest request,
    Set<String> used,
    YildiznameNarrativeStructuredResult result,
  ) {
    for (final required in const [
      'placement.sun',
      'placement.moon',
      'angle.ascendant',
    ]) {
      if (request.factRefs.contains(required) && !used.contains(required)) {
        throw YildiznameResultException(
          YildiznameResultErrorKind.coverage,
          required,
        );
      }
    }
    final personal = _personalSocial.where(used.contains).length;
    final available = _personalSocial.where(request.factRefs.contains).length;
    if (available >= 2 && personal < 2) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.coverage,
        'personalPlanets',
      );
    }
    if (request.aspects.isNotEmpty &&
        !used.any((r) => r.startsWith('aspect.'))) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.coverage,
        'aspect',
      );
    }
    if (!used.any((r) => r.startsWith('angle.') || r.startsWith('house.'))) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.coverage,
        'houseOrAngle',
      );
    }
    final hasSynthesis = result.sections.any((s) => s.factRefs.length >= 2) ||
        result.summary.factRefs.length >= 2;
    if (!hasSynthesis) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.synthesis,
        'needMultiFact',
      );
    }
    final onlySun = used.length == 1 && used.contains('placement.sun');
    if (onlySun) {
      throw YildiznameResultException(
        YildiznameResultErrorKind.genericity,
        'sunOnly',
      );
    }
  }
}
