/// Honest Premium journey copy — value, never fear or withheld bait.
library;

import '../../../core/l10n/l10n.dart';
import '../models/oracle_next_action.dart';
import 'oracle_next_action_copy.dart';

abstract final class OracleJourneyPremiumCopy {
  OracleJourneyPremiumCopy._();

  static String softTitle() => OraclyL10n.t('oracle.journey.soft.title');

  static String softBody(OracleNextAction action) {
    return OraclyL10n.t('oracle.journey.soft.body').replaceAll(
      '{theme}',
      OracleNextActionCopy.themeLabel(action),
    );
  }

  static String softCta() => OraclyL10n.t('oracle.journey.soft.cta');

  static String archiveSummary({
    required String theme,
    required int sources,
    required int occurrences,
  }) {
    return OraclyL10n.t('oracle.journey.archive.summary')
        .replaceAll('{theme}', theme)
        .replaceAll('{sources}', '$sources')
        .replaceAll('{n}', '$occurrences');
  }

  static String orCompare({
    required String theme,
    required String earlierArea,
    required String laterArea,
  }) {
    return OraclyL10n.t('oracle.journey.or.compare')
        .replaceAll('{theme}', theme)
        .replaceAll('{earlier}', earlierArea)
        .replaceAll('{later}', laterArea);
  }
}
