/// Keşfet hub copy.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/modules/oracly_feature_id.dart';

abstract final class ExploreCopy {
  ExploreCopy._();
  static String _t(String key) => OraclyL10n.t(key);
  static String get screenTitle => _t('explore.title');
  static String get subtitle => _t('explore.subtitle');
  static String get featuredSubtitle => _t('explore.featured');
  static String get modulesLabel => _t('explore.modules');
  static String get orHint => _t('explore.or_hint');
  static String moduleHint(OraclyFeatureId id) => switch (id) {
        OraclyFeatureId.palm => _t('explore.hint.palm'),
        OraclyFeatureId.dream => _t('explore.hint.dream'),
        OraclyFeatureId.astrology => _t('explore.hint.astrology'),
        OraclyFeatureId.starMap => _t('explore.hint.starmap'),
        OraclyFeatureId.soulMate => _t('explore.hint.soulmate'),
        _ => _t('explore.hint.generic'),
      };
}
