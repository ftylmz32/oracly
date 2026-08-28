/// EPIC-015 — Living home greeting mapped from experience orchestrator.
library;

import '../../features/premium/models/personalization_models.dart';
import '../copy/first_session_copy.dart';
import '../experience/domain/models/experience_context.dart';
import '../experience/domain/models/greeting_context.dart';
import '../universe/oracly_universe_state.dart';
import 'living_universe_copy.dart';
import 'or_phrase_rotator.dart';

abstract final class LivingGreetingCopy {
  LivingGreetingCopy._();

  static const _intros = [
    'Merhaba',
    'Hoş geldin',
    'Buradasın',
  ];

  static const _newJourney = [
    'İlk adımın sessizce başlıyor.',
    'Yolculuk henüz açılıyor — acele yok.',
    'Burada birlikte keşfedeceğiz.',
  ];

  static const _returningToday = [
    'Bugün ritüelin seni bekliyor.',
    'Günün bir parçası hâlâ açık.',
    'Kaldığın yerden devam edebilirsin — zorunlu değil.',
  ];

  static String greetingLabel({
    required ExperienceContext experience,
    required DateTime asOf,
    String? userName,
  }) {
    if (experience.greeting.tone == GreetingTone.newJourney) {
      return FirstSessionCopy.homeGreeting;
    }
    return OrPhraseRotator.daily(
      pool: _intros,
      day: asOf,
      salt: userName ?? 'guest',
    );
  }

  static String subtitle({
    required ExperienceContext experience,
    required OraclyUniverseState universe,
    required PersonalizationSettings settings,
    required DateTime asOf,
    int? daysAway,
  }) {
    if (experience.greeting.tone == GreetingTone.newJourney) {
      return OrPhraseRotator.daily(pool: _newJourney, day: asOf);
    }

    if (experience.greeting.tone == GreetingTone.returning) {
      return OrPhraseRotator.daily(pool: _returningToday, day: asOf);
    }

    return LivingUniverseCopy.atmosphericLine(
      universe: universe,
      asOf: asOf,
      daysAway: daysAway,
      streak: settings.currentStreak,
    );
  }
}
