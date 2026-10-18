/// Home introduction invite copy — short, warm, honest about what is used.
library;

import '../../../core/l10n/l10n.dart';

abstract final class HomeInviteCopy {
  HomeInviteCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get title => _t('home.invite.title');
  static String get body => _t('home.invite.body');
  static String get cta => _t('home.invite.cta');
  static String get later => _t('home.invite.later');
}
