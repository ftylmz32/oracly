/// Locale helpers for Yildizname result presentation.
library;

import '../../../core/l10n/l10n.dart';
import '../../birth_chart/models/zodiac_sign_id.dart';
import '../../birth_chart/services/chart_insight_locale.dart';
import '../models/star_map_reading.dart';

abstract final class StarMapInsightLocale {
  StarMapInsightLocale._();

  static String planetName(String id) => OraclyL10n.t('planet.$id');

  static String planetInfluence(String id) =>
      OraclyL10n.t('star.planet.$id.influence');

  static String planetNote(String id, int shift) =>
      OraclyL10n.t('star.planet.$id.note.${shift % 3}');

  static String polarityLabel(StarMapPolarity polarity) => switch (polarity) {
        StarMapPolarity.supportive => OraclyL10n.t('star.polarity.supportive'),
        StarMapPolarity.challenging => OraclyL10n.t('star.polarity.challenging'),
        StarMapPolarity.balanced => OraclyL10n.t('star.polarity.balanced'),
      };

  static String signName(ZodiacSignId sign) =>
      sign.labeled(OraclyL10n.code);

  static String joinAnd(List<String> parts) => ChartInsightLocale.joinAnd(parts);
}