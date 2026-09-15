/// Home personalization — greeting + ritual welcome. No invented names.
library;

import '../l10n/l10n.dart';
import '../universe/oracly_ritual_time.dart';
import 'birthday_ritual.dart';
import 'home_greeting_name.dart';

abstract final class HomePersonalCopy {
  HomePersonalCopy._();

  static String greeting({
    required OraclyRitualTime time,
    String? profileName,
    bool isBirthday = false,
  }) {
    if (isBirthday) return BirthdayRitual.greeting;
    final firstName = HomeGreetingName.firstNameOrNull(profileName);
    // No trustworthy first name — a bare time-of-day greeting, never a
    // placeholder word like "Traveler"/"Guest" standing in for a name.
    if (firstName == null) return _hello(time);
    return '${_hello(time)}, $firstName';
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
