/// Birthday state from a real saved birth date. No astrology.
library;

import '../l10n/l10n.dart';

abstract final class BirthdayRitual {
  BirthdayRitual._();

  static String get greeting => OraclyL10n.t('home.birthday_greeting');
  static String get cardBody => OraclyL10n.t('home.birthday_body');

  static bool isToday({
    required DateTime? birthDate,
    required DateTime now,
  }) {
    if (birthDate == null) return false;
    return birthDate.month == now.month && birthDate.day == now.day;
  }
}
