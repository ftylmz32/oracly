/// Builds today's astrology reading from sign + calendar day.
library;

import '../../../core/l10n/l10n.dart';
import '../../content/astrology/models/astrology_content.dart';
import '../../personal_discovery/models/personal_discovery_profile.dart';
import '../data/astrology_daily_copy.dart';
import '../data/astrology_detail_copy.dart';
import '../models/astrology_daily_reading.dart';
import 'astrology_personalization.dart';

abstract final class AstrologyDailyReadingService {
  AstrologyDailyReadingService._();

  static AstrologyDailyReading build(
    ZodiacSignContent sign, {
    DateTime? now,
    PersonalDiscoveryProfile? profile,
  }) {
    final day = now ?? DateTime.now();
    final tone = _tone(sign.id, day);
    final copy = AstrologyDailyCopy.forId(sign.id);
    final extra = AstrologyDetailCopy.forId(sign.id);
    final overall = copy.overall[tone.clamp(0, copy.overall.length - 1)];

    final base = AstrologyDailyReading(
      personality: AstrologyDailyCopy.personality(sign),
      overall: overall,
      love: copy.love,
      career: copy.career,
      money: copy.money,
      advice: copy.advice,
      energy: extra.energy,
      emotion: extra.emotion,
      opportunity: extra.opportunity,
      caution: extra.caution,
    );
    return AstrologyPersonalization.overlay(
      base: base,
      signName: OraclyL10n.t('zodiac.${sign.id}'),
      profile: profile,
      day: day,
    );
  }

  static int _tone(String signId, DateTime day) {
    return (day.year * 19 + day.month * 31 + day.day + signId.length) % 3;
  }
}
