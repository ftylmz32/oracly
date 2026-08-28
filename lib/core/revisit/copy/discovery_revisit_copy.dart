/// Smart reopen copy — shared prompt and three honest actions.

library;



import '../../../core/l10n/l10n.dart';



abstract final class DiscoveryRevisitCopy {

  DiscoveryRevisitCopy._();



  static String _t(String key) => OraclyL10n.t(key);



  static String get prompt => _t('revisit.or.prompt');

  static String get newSpread => _t('revisit.or.action.new_spread');

  static String get openPrior => _t('revisit.or.action.open');

  static String get newAngle => _t('revisit.or.action.angle');

}


