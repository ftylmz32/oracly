/// Builds favorite moment drafts from real feature data.
library;

import '../../../core/domain/models/reading.dart';
import '../../ai/domain/models/ai_message.dart';
import '../../astrology/models/astrology_daily_reading.dart';
import '../../coffee/models/coffee_reading.dart';
import '../../palm/models/palm_reading.dart';
import '../../daily_message/models/daily_message.dart';
import '../../star_map/artifacts/yildizname_artifact.dart';
import '../models/favorite_moment.dart';
import 'favorite_moment_astrology.dart';
import 'favorite_moment_star_map.dart';
import 'favorite_moment_tarot.dart';
import 'favorite_moment_text.dart';

abstract final class FavoriteMomentFactory {
  FavoriteMomentFactory._();

  static FavoriteMoment tarot(ReadingModel reading) =>
      FavoriteMomentTarot.fromReading(reading);

  static FavoriteMoment tarotLive({
    required String sessionId,
    required DateTime at,
    required String cardName,
    required String cardAsset,
    required String insight,
    bool isReversed = false,
  }) =>
      FavoriteMomentTarot.fromLive(
        sessionId: sessionId,
        at: at,
        cardName: cardName,
        cardAsset: cardAsset,
        insight: insight,
        isReversed: isReversed,
      );

  static FavoriteMoment coffee(CoffeeReading reading) => FavoriteMoment(
        id: '${FavoriteMomentSource.coffee.name}:${reading.id}',
        source: FavoriteMomentSource.coffee,
        sourceRef: reading.id,
        savedAt: DateTime.now(),
        occurredAt: reading.createdAt,
        quote: FavoriteMomentText.firstNonEmpty([
          reading.takeaway,
          reading.overall,
          reading.nearFuture,
        ]),
        visualAsset: reading.imagePath,
        visualLabel: reading.symbols.isEmpty ? null : reading.symbols.first.name,
      );

  static FavoriteMoment palm(PalmReading reading) => FavoriteMoment(
        id: '${FavoriteMomentSource.palm.name}:${reading.id}',
        source: FavoriteMomentSource.palm,
        sourceRef: reading.id,
        savedAt: DateTime.now(),
        occurredAt: reading.createdAt,
        quote: FavoriteMomentText.firstNonEmpty([
          reading.overall,
          ...reading.themes,
        ]),
        visualAsset: reading.imagePath,
        visualLabel: reading.symbols.isEmpty ? null : reading.symbols.first,
      );

  static FavoriteMoment dream({
    required String id,
    required DateTime at,
    required String narrative,
    required String analysis,
  }) {
    return FavoriteMoment(
      id: '${FavoriteMomentSource.dream.name}:$id',
      source: FavoriteMomentSource.dream,
      sourceRef: id,
      savedAt: DateTime.now(),
      occurredAt: at,
      quote: FavoriteMomentText.firstNonEmpty([analysis, narrative]),
      visualLabel: FavoriteMomentText.clip(narrative, max: 48),
    );
  }

  static FavoriteMoment companion(AIMessage message) {
    return FavoriteMoment(
      id: '${FavoriteMomentSource.companion.name}:${message.id}',
      source: FavoriteMomentSource.companion,
      sourceRef: message.id,
      savedAt: DateTime.now(),
      occurredAt: message.createdAt,
      quote: FavoriteMomentText.clip(message.content),
    );
  }

  static FavoriteMoment daily(DailyMessage message) {
    return FavoriteMoment(
      id: '${FavoriteMomentSource.dailyMessage.name}:${message.dateKey}',
      source: FavoriteMomentSource.dailyMessage,
      sourceRef: message.dateKey,
      savedAt: DateTime.now(),
      occurredAt: message.day,
      quote: FavoriteMomentText.clip(message.text),
      visualLabel: message.sunSign,
    );
  }

  static FavoriteMoment starMap({
    required String ref,
    required DateTime at,
    required String title,
    required String insight,
  }) =>
      FavoriteMomentStarMap.fromLeaf(
        ref: ref,
        at: at,
        title: title,
        insight: insight,
      );

  static FavoriteMoment starMapArtifact({
    required String artifactId,
    required DateTime at,
    required String title,
    required String insight,
  }) =>
      FavoriteMomentStarMap.artifact(
        artifactId: artifactId,
        at: at,
        title: title,
        insight: insight,
      );

  static FavoriteMoment starMapFromArtifact(YildiznameArtifact artifact) =>
      FavoriteMomentStarMap.fromArtifact(artifact);

  static FavoriteMoment astrology({
    required String signId,
    required DateTime at,
    required String signLabel,
    required AstrologyDailyReading reading,
  }) =>
      FavoriteMomentAstrology.fromDaily(
        signId: signId,
        at: at,
        signLabel: signLabel,
        reading: reading,
      );
}
