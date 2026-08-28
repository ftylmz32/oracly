/// Season spoken from a real birth month — climate, not a natal claim.
library;

import '../../../core/l10n/l10n.dart';

abstract final class SoulMateSeason {
  SoulMateSeason._();

  static String label(DateTime birth) {
    final month = birth.month;
    if (month == 12 || month <= 2) {
      return OraclyL10n.t('soulmate.season.winter');
    }
    if (month <= 5) return OraclyL10n.t('soulmate.season.spring');
    if (month <= 8) return OraclyL10n.t('soulmate.season.summer');
    return OraclyL10n.t('soulmate.season.autumn');
  }
}
