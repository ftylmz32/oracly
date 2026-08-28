/// Home personalization — greeting + ritual welcome. No invented names.
library;

import '../l10n/l10n.dart';
import '../universe/oracly_ritual_time.dart';
import 'birthday_ritual.dart';
import 'first_session_copy.dart';

abstract final class HomePersonalCopy {
  HomePersonalCopy._();

  static String greeting({
    required OraclyRitualTime time,
    String? profileName,
    bool isBirthday = false,
  }) {
    if (isBirthday) return BirthdayRitual.greeting;
    final trimmed = (profileName ?? '').trim();
    final who = trimmed.isEmpty ? FirstSessionCopy.homeGuestName : trimmed;
    return '${_hello(time)}, $who';
  }

  static String ritualWelcome(
    OraclyRitualTime time, {
    bool isBirthday = false,
  }) {
    if (isBirthday) return BirthdayRitual.cardBody;
    return switch (time) {
      OraclyRitualTime.morning => OraclyL10n.t('home.ritual.morning'),
      OraclyRitualTime.afternoon => OraclyL10n.t('home.ritual.afternoon'),
      OraclyRitualTime.evening => OraclyL10n.t('home.ritual.evening'),
      OraclyRitualTime.night => OraclyL10n.t('home.ritual.night'),
    };
  }

  static String _hello(OraclyRitualTime time) => switch (time) {
        OraclyRitualTime.morning => OraclyL10n.t('home.hello.morning'),
        OraclyRitualTime.afternoon => OraclyL10n.t('home.hello.afternoon'),
        OraclyRitualTime.evening => OraclyL10n.t('home.hello.evening'),
        OraclyRitualTime.night => OraclyL10n.t('home.hello.night'),
      };
}
