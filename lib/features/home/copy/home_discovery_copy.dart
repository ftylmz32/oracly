/// Home discovery grid — TR / EN / RU titles and subtitles.
library;

import '../../../core/l10n/l10n.dart';
import '../../../core/modules/oracly_feature_id.dart';

abstract final class HomeDiscoveryCopy {
  HomeDiscoveryCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String title(OraclyFeatureId id) => _t(switch (id) {
        OraclyFeatureId.coffee => 'home.discovery.coffee.title',
        OraclyFeatureId.palm => 'home.discovery.palm.title',
        OraclyFeatureId.astrology => 'home.discovery.astrology.title',
        OraclyFeatureId.starMap => 'home.discovery.star_map.title',
        OraclyFeatureId.soulMate => 'home.discovery.soulmate.title',
        OraclyFeatureId.tarot => 'home.discovery.tarot.title',
        OraclyFeatureId.dream => 'home.discovery.dream.title',
        _ => '',
      });

  static String caption(OraclyFeatureId id) => _t(switch (id) {
        OraclyFeatureId.coffee => 'home.discovery.coffee.caption',
        OraclyFeatureId.palm => 'home.discovery.palm.caption',
        OraclyFeatureId.astrology => 'home.discovery.astrology.caption',
        OraclyFeatureId.starMap => 'home.discovery.star_map.caption',
        OraclyFeatureId.soulMate => 'home.discovery.soulmate.caption',
        OraclyFeatureId.tarot => 'home.discovery.tarot.caption',
        OraclyFeatureId.dream => 'home.discovery.dream.caption',
        _ => '',
      });

  static String semantics(OraclyFeatureId id) => _t(switch (id) {
        OraclyFeatureId.coffee => 'home.discovery.coffee.semantics',
        OraclyFeatureId.palm => 'home.discovery.palm.semantics',
        OraclyFeatureId.astrology => 'home.discovery.astrology.semantics',
        OraclyFeatureId.starMap => 'home.discovery.star_map.semantics',
        OraclyFeatureId.soulMate => 'home.discovery.soulmate.semantics',
        OraclyFeatureId.tarot => 'home.discovery.tarot.semantics',
        OraclyFeatureId.dream => 'home.discovery.dream.semantics',
        _ => title(id),
      });
}
