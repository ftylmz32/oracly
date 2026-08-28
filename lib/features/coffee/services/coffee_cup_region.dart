/// Reads cup zones from the vision text only. Never invents a region.
library;

import '../../../core/l10n/l10n.dart';

abstract final class CoffeeCupRegion {
  CoffeeCupRegion._();

  static const _rim = ['ağız', 'kenar', 'rim'];
  static const _wall = ['duvar', 'wall', 'iç yüzey'];
  static const _base = ['dip', 'taban', 'base', 'bottom'];
  static const _handle = ['kulp', 'handle'];

  static String place(String observation) {
    final zone = resolve(observation);
    if (zone.isEmpty) return '';
    return OraclyL10n.t('cup.zone.$zone');
  }

  static String time(String observation, {String seen = ''}) {
    final zone = resolve(observation);
    if (zone.isEmpty) return '';
    final mark = seen.trim().isEmpty ? 'bu iz' : seen.trim();
    return OraclyL10n.t('cup.read.time.$zone').replaceAll('{seen}', mark);
  }

  static String resolve(String observation) {
    final text = observation.toLowerCase();
    if (text.isEmpty) return '';
    if (_has(text, _rim)) return 'rim';
    if (_has(text, _handle)) return 'handle';
    if (_has(text, _wall)) return 'wall';
    if (_has(text, _base)) return 'base';
    return '';
  }

  static bool _has(String text, List<String> keys) =>
      keys.any(text.contains);
}
