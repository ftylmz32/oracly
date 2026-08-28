/// Share reopen copy — public glimpse, never a private dump.
library;

import '../../../core/l10n/l10n.dart';
import '../../discovery_share/models/shareable_discovery.dart';
import '../../discovery_share/copy/discovery_share_copy.dart';

abstract final class ShareReopenCopy {
  ShareReopenCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get title => _t('share.open.title');
  static String get footnote => _t('share.open.footnote');
  static String get openFeature => _t('share.open.feature');
  static String get openMine => _t('share.open.mine');
  static String get signIn => _t('share.open.signin');
  static String get missing => _t('share.open.missing');

  static String typeLabel(DiscoveryShareKind kind) {
    return switch (kind) {
      DiscoveryShareKind.coffee => DiscoveryShareCopy.coffeeType,
      DiscoveryShareKind.palm => DiscoveryShareCopy.palmType,
      DiscoveryShareKind.tarot => DiscoveryShareCopy.tarotType,
      DiscoveryShareKind.astrology => DiscoveryShareCopy.astrologyType,
      DiscoveryShareKind.starMap => DiscoveryShareCopy.starMapType,
      DiscoveryShareKind.soulMate => DiscoveryShareCopy.soulMateType,
      DiscoveryShareKind.dailyInsight => DiscoveryShareCopy.dailyType,
    };
  }
}
