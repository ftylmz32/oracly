/// Durable favorite evidence — no volatile savedAt in presentation equality.
library;

import 'package:flutter/foundation.dart';

import '../../favorite_moments/models/favorite_moment.dart';
import '../../favorite_moments/services/favorite_moment_factory.dart';

@immutable
final class YildiznameFavoriteAction {
  const YildiznameFavoriteAction({
    required this.artifactId,
    required this.occurredAt,
    required this.title,
    required this.insight,
  });

  final String artifactId;
  final DateTime occurredAt;
  final String title;
  final String insight;

  /// Matches [FavoriteMomentFactory.starMapArtifact] id / sourceRef.
  /// Wire prefix is the durable FavoriteMomentSource.starMap token.
  String get favoriteId => 'starMap:$artifactId';

  FavoriteMoment toMoment() => FavoriteMomentFactory.starMapArtifact(
        artifactId: artifactId,
        at: occurredAt,
        title: title,
        insight: insight,
      );

  @override
  bool operator ==(Object other) =>
      other is YildiznameFavoriteAction &&
      other.artifactId == artifactId &&
      other.occurredAt == occurredAt &&
      other.title == title &&
      other.insight == insight;

  @override
  int get hashCode => Object.hash(artifactId, occurredAt, title, insight);
}
