/// Input-grounded portrait reading. Never a prediction or arrival claim.
library;

import '../../../core/l10n/l10n.dart';

class SoulMateReadingParts {
  const SoulMateReadingParts({
    required this.energy,
    required this.attraction,
    required this.dynamics,
    required this.feeling,
    required this.yourSide,
  });

  final String energy;
  final String attraction;
  final String dynamics;
  final String feeling;
  final String yourSide;

  String get joined =>
      '$energy\n\n$attraction\n\n$dynamics\n\n$feeling\n\n$yourSide';
}

abstract final class SoulMateInterpretationCatalogue {
  SoulMateInterpretationCatalogue._();

  static SoulMateReadingParts forInputs({
    required String name,
    required String intention,
    required String season,
    required String preference,
    required int tone,
  }) {
    final who = name.trim().isEmpty ? OraclyL10n.t('soulmate.you') : name.trim();
    final energy = _fill(
      _wantsCalm(intention)
          ? 'soulmate.copy.character_calm'
          : 'soulmate.copy.character_near',
      {'season': season},
    );
    final attraction = intention.isEmpty
        ? _fill('soulmate.copy.attraction_plain', {'who': who})
        : _fill('soulmate.copy.attraction_intent', {
            'who': who,
            'intention': intention,
          });
    final dynamics = preference.isEmpty
        ? _fill('soulmate.copy.dynamics_free', {'who': who})
        : _fill('soulmate.copy.dynamics_pref', {
            'who': who,
            'pref': preference,
          });
    final idx = tone % 3;
    return SoulMateReadingParts(
      energy: energy,
      attraction: attraction,
      dynamics: dynamics,
      feeling: _fill('soulmate.copy.feeling.$idx', {'who': who}),
      yourSide: _fill('soulmate.copy.your_side.$idx', {'who': who}),
    );
  }

  static bool _wantsCalm(String intention) {
    final t = intention.toLowerCase();
    return t.contains('sakin') ||
        t.contains('huzur') ||
        t.contains('sessiz') ||
        t.contains('yumuşak') ||
        t.contains('calm') ||
        t.contains('peace') ||
        t.contains('quiet') ||
        t.contains('soft') ||
        t.contains('спокой') ||
        t.contains('тишин') ||
        t.contains('мир');
  }

  static String _fill(String key, Map<String, String> vars) {
    var out = OraclyL10n.t(key);
    for (final entry in vars.entries) {
      out = out.replaceAll('{${entry.key}}', entry.value);
    }
    return out;
  }
}
