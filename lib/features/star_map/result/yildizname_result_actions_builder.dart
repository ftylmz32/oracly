/// Builds typed [YildiznameResultActions] from a result presentation.
///
/// Reuses StarMapInsightCopy, DiscoveryShareBuilder, FavoriteMomentFactory
/// rules — does not invent timestamps or reconstruct raw payloads.
library;

import '../../ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../discovery_share/services/discovery_share_builder.dart';
import '../presentation/reference/star_map_insight_copy.dart';
import 'yildizname_canonical_insight.dart';
import 'yildizname_favorite_action.dart';
import 'yildizname_result_actions.dart';
import 'yildizname_result_presentation.dart';

abstract final class YildiznameResultActionsBuilder {
  YildiznameResultActionsBuilder._();

  static YildiznameResultActions build({
    required YildiznameResultPresentation presentation,
    OracleReadingContext? orContext,
  }) {
    final insight = YildiznameCanonicalInsight.of(presentation);
    final copy = StarMapInsightCopy.fromResult(
      title: presentation.title,
      sections: presentation.sections,
      planets: presentation.planets,
    );
    final share = DiscoveryShareBuilder.starMap(highlight: insight);
    final themes = [
      for (final s in presentation.sections) s.title,
    ];
    final id = presentation.artifactId?.trim();
    final at = presentation.createdAtUtc;
    YildiznameFavoriteAction? favorite;
    if (id != null && id.isNotEmpty && at != null) {
      favorite = YildiznameFavoriteAction(
        artifactId: id,
        occurredAt: at,
        title: presentation.title,
        insight: insight,
      );
    }
    return YildiznameResultActions(
      canonicalInsight: insight,
      copyText: copy,
      share: share,
      orContext: orContext,
      favorite: favorite,
      continuationThemes: List.unmodifiable(themes),
    );
  }
}
