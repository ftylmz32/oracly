/// Seeded coffee-reading turns. Facts only; no cookie openings.
library;

import '../../../core/l10n/l10n.dart';
import 'coffee_cup_region.dart';

abstract final class CoffeeFortuneBeats {
  CoffeeFortuneBeats._();

  static String look({
    required int seed,
    required String seen,
    required String place,
  }) {
    return _fill('cup.read.look.${seed % 5}', {
      'seen': _clip(seen),
      'place': place,
    });
  }

  static String together({
    required int seed,
    required String first,
    required String second,
    required String place,
  }) {
    return _fill('cup.read.together.${seed % 5}', {
      'a': _clip(first),
      'b': _clip(second),
      'place': place,
    });
  }

  static String unsure(String seen) =>
      _fill('cup.read.unsure', {'seen': _clip(seen)});

  static String hedge(String seen) =>
      _fill('cup.read.hedge', {'seen': _clip(seen)});

  static String develop({
    required String observation,
    required Set<String> ids,
    required String seen,
    required int seed,
  }) {
    final zone = CoffeeCupRegion.resolve(observation);
    final nearMark = ids.contains('bird') ||
        ids.contains('letter') ||
        ids.contains('road');
    if (ids.contains('mountain') && !nearMark) {
      return OraclyL10n.t('fortune.cup.wait');
    }
    if (zone == 'base') {
      return _fill('cup.read.develop.base', {'seen': _clip(seen)});
    }
    if (zone == 'wall') {
      return _fill('cup.read.develop.later', {'seen': _clip(seen)});
    }
    if (zone == 'rim') {
      return _fill('cup.read.develop.near.${seed % 2}', {'seen': _clip(seen)});
    }
    if (zone == 'handle') {
      return OraclyL10n.t('cup.read.develop.near.0');
    }
    if (!nearMark) return '';
    return OraclyL10n.t('cup.read.develop.near.0');
  }

  static String ask(Set<String> ids, List<String> themes, [int seed = 0]) {
    final key = _askKey(ids, themes);
    if (key.isEmpty) return '';
    if (seed.abs() % 2 == 1) return OraclyL10n.t('$key.1');
    return OraclyL10n.t(key);
  }

  static String _askKey(Set<String> ids, List<String> themes) {
    if (ids.isEmpty) return '';
    if (ids.contains('bird') || ids.contains('letter')) {
      return 'cup.read.ask.news';
    }
    if (ids.contains('heart') || ids.contains('ring') || ids.contains('person')) {
      return 'cup.read.ask.bind';
    }
    if (ids.contains('mountain')) return 'cup.read.ask.wait';
    if (ids.contains('road') ||
        ids.contains('key') ||
        themes.any(_isPathTheme)) {
      return 'cup.read.ask.change';
    }
    return '';
  }

  static bool _isPathTheme(String raw) {
    final t = raw.trim().toLowerCase();
    return t == 'değişim' ||
        t == 'change' ||
        t == 'karar' ||
        t == 'karar verme' ||
        t == 'decision';
  }

  static String _fill(String key, Map<String, String> values) {
    var out = OraclyL10n.t(key);
    values.forEach((k, v) => out = out.replaceAll('{$k}', v));
    return out.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  static String _clip(String raw) {
    var text = raw.trim();
    while (text.endsWith('.') || text.endsWith(',')) {
      text = text.substring(0, text.length - 1).trim();
    }
    return text;
  }
}
