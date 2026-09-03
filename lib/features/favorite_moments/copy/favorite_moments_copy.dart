/// Favori Anlarım copy — warm, explicit, never surveillance.
library;

import '../../../core/l10n/l10n.dart';
import '../../discovery_journal/copy/discovery_journal_copy.dart';
import '../models/favorite_moment.dart';

abstract final class FavoriteMomentsCopy {
  FavoriteMomentsCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get title => _t('moments.title');
  static String get subtitle => _t('moments.subtitle');
  static String get save => _t('moments.save');
  static String get saved => _t('moments.saved');
  static String get already => _t('moments.already');
  static String get unsave => _t('moments.unsave');
  static String get remove => _t('moments.remove');
  static String get removed => _t('moments.removed');
  static String get emptyTitle => _t('moments.empty_title');
  static String get emptyBody => _t('moments.empty_body');
  static String get openCta => _t('moments.open');
  static String get sourceUnavailable => _t('moments.source_unavailable');
  static String get snapshotNotice => _t('moments.snapshot_notice');

  static String featureLabel(FavoriteMoment moment) =>
      DiscoveryJournalCopy.badge(moment.source.journalKind);
}
