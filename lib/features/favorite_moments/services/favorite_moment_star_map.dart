/// StarMap / Yıldızname favorite drafts — durable artifact ids only.
library;

import '../../star_map/artifacts/yildizname_artifact.dart';
import '../../star_map/artifacts/yildizname_artifact_presentation.dart';
import '../models/favorite_moment.dart';
import 'favorite_moment_text.dart';

abstract final class FavoriteMomentStarMap {
  FavoriteMomentStarMap._();

  /// Durable favorite from a persisted Yıldızname artifact id (`yid_…`).
  static FavoriteMoment artifact({
    required String artifactId,
    required DateTime at,
    required String title,
    required String insight,
  }) {
    return FavoriteMoment(
      id: '${FavoriteMomentSource.starMap.name}:$artifactId',
      source: FavoriteMomentSource.starMap,
      sourceRef: artifactId,
      savedAt: DateTime.now(),
      occurredAt: at,
      quote: FavoriteMomentText.clip(insight),
      visualLabel: title,
    );
  }

  static FavoriteMoment fromArtifact(YildiznameArtifact artifact) {
    final presentation = YildiznameArtifactPresentation.of(artifact);
    final insight = YildiznameArtifactPresentation.summaryQuote(artifact);
    return FavoriteMomentStarMap.artifact(
      artifactId: artifact.id,
      at: artifact.createdAtUtc,
      title: presentation.title.trim().isEmpty
          ? 'Yıldızname'
          : presentation.title,
      insight: insight,
    );
  }

  /// Legacy content-hash ref — tests / old favorites only.
  static FavoriteMoment fromLeaf({
    required String ref,
    required DateTime at,
    required String title,
    required String insight,
  }) {
    return FavoriteMoment(
      id: '${FavoriteMomentSource.starMap.name}:$ref',
      source: FavoriteMomentSource.starMap,
      sourceRef: ref,
      savedAt: DateTime.now(),
      occurredAt: at,
      quote: FavoriteMomentText.clip(insight),
      visualLabel: title,
    );
  }
}
