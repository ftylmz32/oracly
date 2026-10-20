/// Builds today's astrology reading from sign + calendar day.
library;

import '../../../core/l10n/l10n.dart';
import '../../content/astrology/models/astrology_content.dart';
import '../../personal_discovery/models/personal_discovery_profile.dart';
import '../data/astrology_daily_copy.dart';
import '../data/astrology_day_pool_tr.dart';
import '../data/astrology_detail_copy.dart';
import '../../birth_chart/astronomy/astronomia_ephemeris_adapter.dart';
import '../../birth_chart/astronomy/astronomical_ephemeris_port.dart';
import '../models/astrology_daily_reading.dart';
import '../sky/astrology_natal_sky.dart';
import '../sky/astrology_sky_reading.dart';
import '../sky/astrology_transit_engine.dart';
import 'astrology_personalization.dart';

abstract final class AstrologyDailyReadingService {
  AstrologyDailyReadingService._();

  static AstrologyDailyReading build(
    ZodiacSignContent sign, {
    DateTime? now,
    PersonalDiscoveryProfile? profile,
    List<String> selectedThemes = const [],
    AstrologyNatalSky? natalSky,
    AstronomicalEphemerisPort? ephemeris,
  }) {
    final day = now ?? DateTime.now();
    // The person's own sign, in Turkish: written from today's transits to
    // their chart. Any other sign, or no birth data, stays general copy.
    if (natalSky != null &&
        natalSky.sunSign.id == sign.id &&
        _usesTurkishPool) {
      final sky = AstrologyTransitEngine.compute(
        natal: natalSky,
        day: day,
        ephemeris: ephemeris ?? _ephemeris,
      );
      return AstrologySkyReading.compose(
        sky: sky,
        day: day,
        themes: selectedThemes.isNotEmpty
            ? selectedThemes
            : (profile?.observedRecurringLabels ?? const <String>[]),
      );
    }
    final pool = _usesTurkishPool ? kAstrologyDayPoolTr[sign.id] : null;
    final base = pool != null
        ? _fromPool(sign, pool, dayIndex(day))
        : _fromCatalogue(sign, day);
    return AstrologyPersonalization.overlay(
      base: base,
      signName: OraclyL10n.t('zodiac.${sign.id}'),
      profile: profile,
      day: day,
      selectedThemes: selectedThemes,
    );
  }

  /// Whole days since a fixed epoch; stable for a calendar day everywhere.
  static int dayIndex(DateTime day) =>
      DateTime.utc(day.year, day.month, day.day)
          .difference(DateTime.utc(2000))
          .inDays;

  static final _ephemeris = AstronomiaEphemerisAdapter();

  static bool get _usesTurkishPool {
    final code = OraclyL10n.code;
    return code != 'en' && code != 'ru';
  }

  /// Each lane walks its own pool with a sign- and lane-specific offset, so
  /// consecutive days never repeat a lane and lanes do not move in lockstep.
  static AstrologyDailyReading _fromPool(
    ZodiacSignContent sign,
    AstrologyDayPool pool,
    int d,
  ) {
    final s = sign.id.codeUnits.fold<int>(0, (a, c) => a + c);
    String pick(List<String> lane, int salt) =>
        lane[(d + s + salt) % lane.length];
    return AstrologyDailyReading(
      personality: AstrologyDailyCopy.personality(sign),
      overall: pick(pool.overall, 0),
      love: pick(pool.love, 1),
      career: pick(pool.career, 2),
      money: pick(pool.money, 3),
      energy: pick(pool.energy, 4),
      emotion: pick(pool.emotion, 5),
      advice: pick(pool.advice, 6),
      opportunity: pick(pool.opportunity, 7),
      caution: pick(pool.caution, 8),
    );
  }

  static AstrologyDailyReading _fromCatalogue(
    ZodiacSignContent sign,
    DateTime day,
  ) {
    final copy = AstrologyDailyCopy.forId(sign.id);
    final extra = AstrologyDetailCopy.forId(sign.id);
    final tone = (day.year * 19 + day.month * 31 + day.day + sign.id.length) %
        copy.overall.length;
    return AstrologyDailyReading(
      personality: AstrologyDailyCopy.personality(sign),
      overall: copy.overall[tone],
      love: copy.love,
      career: copy.career,
      money: copy.money,
      advice: copy.advice,
      energy: extra.energy,
      emotion: extra.emotion,
      opportunity: extra.opportunity,
      caution: extra.caution,
    );
  }
}
