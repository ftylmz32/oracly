/// Typed Yıldızname result actions — one contract for the result footer.
library;

import 'package:flutter/foundation.dart';

import '../../ai/oracle_conversation/models/oracle_reading_context.dart';
import '../../discovery_share/models/shareable_discovery.dart';
import '../../discovery_share/services/discovery_share_builder.dart';
import 'yildizname_favorite_action.dart';

@immutable
final class YildiznameResultActions {
  const YildiznameResultActions({
    required this.canonicalInsight,
    required this.copyText,
    required this.share,
    this.orContext,
    this.favorite,
    this.continuationThemes = const [],
  });

  static final empty = YildiznameResultActions(
    canonicalInsight: '',
    copyText: '',
    share: DiscoveryShareBuilder.starMap(),
  );

  final String canonicalInsight;
  final String copyText;
  final ShareableDiscovery share;
  final OracleReadingContext? orContext;
  final YildiznameFavoriteAction? favorite;
  final List<String> continuationThemes;

  bool get hasOr => orContext != null;
  bool get hasFavorite => favorite != null;
  bool get isEmpty =>
      identical(this, empty) ||
      (canonicalInsight.isEmpty &&
          copyText.isEmpty &&
          !hasOr &&
          !hasFavorite);

  @override
  bool operator ==(Object other) {
    if (other is! YildiznameResultActions) return false;
    if (other.canonicalInsight != canonicalInsight ||
        other.copyText != copyText ||
        other.share.kind != share.kind ||
        other.share.highlight != share.highlight ||
        other.share.typeLabel != share.typeLabel ||
        other.favorite != favorite ||
        !listEquals(other.continuationThemes, continuationThemes)) {
      return false;
    }
    return _orEquals(other.orContext, orContext);
  }

  @override
  int get hashCode => Object.hash(
    canonicalInsight,
    copyText,
    share.kind,
    share.highlight,
    share.typeLabel,
    favorite,
    orContext?.sessionId,
    orContext?.interpretationSummary,
    Object.hashAll(continuationThemes),
  );

  static bool _orEquals(OracleReadingContext? a, OracleReadingContext? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return a.sessionId == b.sessionId &&
        a.kind == b.kind &&
        a.readingTitle == b.readingTitle &&
        a.interpretationSummary == b.interpretationSummary &&
        a.fullInterpretation == b.fullInterpretation &&
        a.cardsSummary == b.cardsSummary;
  }
}
