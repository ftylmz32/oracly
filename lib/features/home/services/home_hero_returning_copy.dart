/// Maps GreetingTone.returning onto Home hero strings - no new decisions.
library;

import '../../../core/experience/domain/models/experience_context.dart';
import '../../../core/experience/domain/models/greeting_context.dart';
import '../../../core/personality/living_greeting_copy.dart';
import '../../../core/universe/oracly_universe_state.dart';
import '../../premium/models/personalization_models.dart';

/// Returning-user strings from the existing living greeting system.
abstract final class HomeHeroReturningCopy {
  HomeHeroReturningCopy._();

  /// Default hero plate - hello + invite when tone is returning; else null.
  static ({String hello, String invite})? defaultPlate({
    required ExperienceContext? experience,
    required OraclyUniverseState universe,
    required PersonalizationSettings settings,
    String? userName,
  }) {
    if (!_isReturning(experience)) return null;
    final ctx = experience!;
    final asOf = ctx.generatedAt;
    final name = _name(userName);
    return (
      hello: LivingGreetingCopy.greetingLabel(
        experience: ctx,
        asOf: asOf,
        userName: name,
      ),
      invite: LivingGreetingCopy.subtitle(
        experience: ctx,
        universe: universe,
        settings: settings,
        asOf: asOf,
      ),
    );
  }

  /// Continuity hero - soft greeting only; never replaces card invite/CTA.
  static String? greetingOnly({
    required ExperienceContext? experience,
    String? userName,
  }) {
    if (!_isReturning(experience)) return null;
    final ctx = experience!;
    return LivingGreetingCopy.greetingLabel(
      experience: ctx,
      asOf: ctx.generatedAt,
      userName: _name(userName),
    );
  }

  static bool _isReturning(ExperienceContext? experience) =>
      experience != null && experience.greeting.tone == GreetingTone.returning;

  static String? _name(String? raw) {
    final trimmed = raw?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
