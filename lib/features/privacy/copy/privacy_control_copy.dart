/// Privacy Control Center copy.
library;

import '../../../core/l10n/l10n.dart';

abstract final class PrivacyControlCopy {
  PrivacyControlCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get title => _t('privacy.control.title');
  static String get subtitle => _t('privacy.control.subtitle');
  static String get sectionData => _t('privacy.control.section.data');
  static String get sectionActions => _t('privacy.control.section.actions');
  static String get profile => _t('privacy.control.profile');
  static String get moments => _t('privacy.control.moments');
  static String get history => _t('privacy.control.history');
  static String get memory => _t('privacy.control.memory');
  static String get notifications => _t('privacy.control.notifications');
  static String get voice => _t('privacy.control.voice');
  static String get empty => _t('privacy.control.empty');
  static String get memoryEmpty => _t('privacy.control.memory.empty');
  static String get on => _t('privacy.control.on');
  static String get off => _t('privacy.control.off');
  static String count(int n) =>
      _t('privacy.control.count').replaceAll('{n}', '$n');

  static String get clearHistory => _t('privacy.control.clear.history');
  static String get clearHistorySub => _t('privacy.control.clear.history.sub');
  static String get clearFavorites => _t('privacy.control.clear.favorites');
  static String get clearFavoritesSub =>
      _t('privacy.control.clear.favorites.sub');
  static String get resetMemory => _t('privacy.control.reset.memory');
  static String get resetMemorySub => _t('privacy.control.reset.memory.sub');

  static String get confirmHistoryTitle =>
      _t('privacy.control.confirm.history.title');
  static String get confirmHistoryBody =>
      _t('privacy.control.confirm.history.body');
  static String get confirmFavoritesTitle =>
      _t('privacy.control.confirm.favorites.title');
  static String get confirmFavoritesBody =>
      _t('privacy.control.confirm.favorites.body');
  static String get confirmMemoryTitle =>
      _t('privacy.control.confirm.memory.title');
  static String get confirmMemoryBody =>
      _t('privacy.control.confirm.memory.body');

  static String get successHistory => _t('privacy.control.success.history');
  static String get successFavorites => _t('privacy.control.success.favorites');
  static String get successMemory => _t('privacy.control.success.memory');

  static String get deleteAccount => _t('privacy.control.delete.account');
  static String get deleteAccountSub => _t('privacy.control.delete.account.sub');
  static String get confirmDeleteTitle =>
      _t('privacy.control.delete.confirm.title');
  static String get confirmDeleteBody =>
      _t('privacy.control.delete.confirm.body');
  static String get confirmDeleteAction =>
      _t('privacy.control.delete.confirm.action');
  static String get successDelete => _t('privacy.control.delete.success');
}
