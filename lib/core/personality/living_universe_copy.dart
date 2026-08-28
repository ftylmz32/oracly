/// EPIC-015 — Contextual universe whispers (subtle, never loud).
library;

import '../universe/oracly_ritual_time.dart';
import '../universe/oracly_season.dart';
import '../universe/oracly_universe_state.dart';
import 'or_phrase_rotator.dart';

abstract final class LivingUniverseCopy {
  LivingUniverseCopy._();

  static const morning = [
    'Yeni bir gökyüzü sessizce açılıyor.',
    'Sabah, hafif bir nefes gibi geliyor.',
    'Gün, acele etmeden başlıyor.',
  ];

  static const afternoon = [
    'Gün ortasında bile bir sakinlik var.',
    'Işık yumuşak — düşünmek için alan bırakıyor.',
    'Zaman biraz yavaşlıyor gibi.',
  ];

  static const evening = [
    'Akşam, sessiz bir eşlikçi gibi.',
    'Gün kapanırken renkler derinleşiyor.',
    'Alacakaranlık, yumuşak bir eşik.',
  ];

  static const night = [
    'Yıldızlar bu gece daha yumuşak konuşuyor.',
    'Gece, dinlemek için geniş bir alan.',
    'Karanlık acele etmez — sen de etmek zorunda değilsin.',
  ];

  static const welcomeBack = [
    'Tekrar hoş geldin. Yerin seni bekliyordu.',
    'Geri döndün — burası hâlâ senin.',
    'Aradan geçen süre sessiz kalmış. Devam etmek zorunda değilsin.',
  ];

  static const streakSeven = [
    'Ritüelin derinleşiyor — kendiliğinden, baskısız.',
    'Yedi gün bir arada — bu bir alışkanlıktan fazlası olabilir.',
    'Süreklilik sessizce büyüyor.',
  ];

  static const contemplativeSky = [
    'Gökyüzü bugün düşünceli görünüyor.',
    'Hava ağır değil — sadece düşünmeye davet ediyor.',
    'Bulutlar acele etmiyor; sen de etmek zorunda değilsin.',
  ];

  static const livingEvent = [
    'Evren bugün hafif bir işaret bıraktı.',
    'Uzak bir ışık geçti — belki senin için değil, belki seninle.',
    'Nadir bir an — fark etmek yeterli olabilir.',
  ];

  static String atmosphericLine({
    required OraclyUniverseState universe,
    required DateTime asOf,
    int? daysAway,
    int streak = 0,
  }) {
    if (streak >= 7) {
      return OrPhraseRotator.daily(pool: streakSeven, day: asOf, salt: 'streak');
    }

    if (daysAway != null && daysAway >= 3) {
      return OrPhraseRotator.daily(
        pool: welcomeBack,
        day: asOf,
        salt: 'return_$daysAway',
      );
    }

    if (universe.livingEvent != null) {
      return OrPhraseRotator.daily(
        pool: livingEvent,
        day: asOf,
        salt: universe.livingEvent!.kind.name,
      );
    }

    if (universe.season == OraclySeason.autumn &&
        universe.ritualTime == OraclyRitualTime.afternoon) {
      return OrPhraseRotator.daily(
        pool: contemplativeSky,
        day: asOf,
        salt: 'contemplative',
      );
    }

    final pool = switch (universe.ritualTime) {
      OraclyRitualTime.morning => morning,
      OraclyRitualTime.afternoon => afternoon,
      OraclyRitualTime.evening => evening,
      OraclyRitualTime.night => night,
    };

    return OrPhraseRotator.daily(
      pool: pool,
      day: asOf,
      salt: universe.ritualTime.name,
    );
  }
}
