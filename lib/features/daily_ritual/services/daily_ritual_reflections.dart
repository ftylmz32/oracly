/// EPIC-011 — Thoughtful daily reflections tied to living universe state.
library;

import '../../../core/copy/home_personal_copy.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/universe/oracly_living_event.dart';
import '../../../core/universe/oracly_moon_phase.dart';
import '../../../core/universe/oracly_ritual_time.dart';
import '../../../core/universe/oracly_season.dart';
import '../../../core/universe/oracly_universe_state.dart';
import '../../tarot/copy/tarot_polish_copy.dart';
import '../../tarot/domain/models/tarot_spread.dart';
import '../../tarot/economy/tarot_economy.dart';
import '../copy/card_of_the_day_copy.dart';

/// Deterministic, atmosphere-aware copy — never predictive, never urgent.
abstract final class DailyRitualReflections {
  DailyRitualReflections._();

  static String _t(String key) => OraclyL10n.t(key);

  static String welcome(
    OraclyUniverseState state, {
    bool isBirthday = false,
  }) =>
      HomePersonalCopy.ritualWelcome(
        state.ritualTime,
        isBirthday: isBirthday,
      );

  /// Wall-clock ritual window — not an energy score.
  static String ritualLabel(OraclyUniverseState state) => switch (state.ritualTime) {
        OraclyRitualTime.morning => _t('ritual.morning'),
        OraclyRitualTime.afternoon => _t('ritual.afternoon'),
        OraclyRitualTime.evening => _t('ritual.evening'),
        OraclyRitualTime.night => _t('ritual.night'),
      };

  static String teaser(OraclyUniverseState state) {
    if (state.livingEvent != null) return _t('ritual.teaser.rare');
    return _t('ritual.teaser.quiet');
  }

  static String reflection(OraclyUniverseState state) {
    final dayKey =
        state.moment.year * 10000 + state.moment.month * 100 + state.moment.day;
    final pool = _poolKeysFor(state);
    return _t(pool[dayKey % pool.length]);
  }

  static String closing() => _t('ritual.closing');

  /// Honest CTA — first open draws; later opens reopen the same card.
  static String drawCta({bool drawn = false}) {
    if (drawn) return CardOfTheDayCopy.openCta;
    final cost = TarotEconomy.costFor(TarotSpreadType.single);
    if (cost == null || cost <= 0) return CardOfTheDayCopy.drawCta;
    return '${CardOfTheDayCopy.drawCta} · ${TarotPolishCopy.gemCost(cost)}';
  }

  static List<String> _poolKeysFor(OraclyUniverseState state) {
    final ritual = state.ritualTime;
    final season = state.season;
    final moon = state.moonPhase;

    if (state.livingEvent?.kind == OraclyLivingEventKind.shootingStar) {
      return _keys('shooting_star', 3);
    }
    if (moon == OraclyMoonPhase.fullMoon) {
      return _keys('full_moon', 3);
    }

    return switch (ritual) {
      OraclyRitualTime.morning => switch (season) {
          OraclySeason.spring => _keys('morning_spring', 3),
          OraclySeason.summer => _keys('morning_summer', 3),
          OraclySeason.autumn => _keys('morning_autumn', 3),
          OraclySeason.winter => _keys('morning_winter', 3),
        },
      OraclyRitualTime.afternoon => _keys('afternoon', 4),
      OraclyRitualTime.evening => _keys('evening', 4),
      OraclyRitualTime.night => _keys('night', 4),
    };
  }

  static List<String> _keys(String pool, int count) => [
        for (var i = 0; i < count; i++) 'ritual.pool.$pool.$i',
      ];
}
