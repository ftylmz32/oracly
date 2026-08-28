/// Builds favorite moment drafts from real feature data.
library;

import '../../../core/domain/models/reading.dart';
import '../../ai/domain/models/ai_message.dart';
import '../../astrology/models/astrology_daily_reading.dart';
import '../../coffee/models/coffee_reading.dart';
import '../../palm/models/palm_reading.dart';
import '../../daily_message/models/daily_message.dart';
import '../../tarot/history/tarot_history_privacy.dart';
import '../models/favorite_moment.dart';
import 'favorite_moment_text.dart';

abstract final class FavoriteMomentFactory {
  FavoriteMomentFactory._();

  static FavoriteMoment tarot(ReadingModel reading) {
    final ref = reading.id;
    return FavoriteMoment(
      id: '${FavoriteMomentSource.tarot.name}:$ref',
      source: FavoriteMomentSource.tarot,
      sourceRef: ref,
      savedAt: DateTime.now(),
      occurredAt: reading.createdAt,
      quote: TarotHistoryPrivacy.shortInsight(reading),
      visualAsset: reading.cardImageAsset,
      visualLabel: reading.cardName,
    );
  }

  static FavoriteMoment tarotLive({
    required String sessionId,
    required DateTime at,
    required String cardName,
    required String cardAsset,
    required String insight,
  }) {
    return FavoriteMoment(
      id: '${FavoriteMomentSource.tarot.name}:$sessionId',
      source: FavoriteMomentSource.tarot,
      sourceRef: sessionId,
      savedAt: DateTime.now(),
      occurredAt: at,
      quote: FavoriteMomentText.clip(insight),
      visualAsset: cardAsset,
      visualLabel: cardName,
    );
  }

  static FavoriteMoment coffee(CoffeeReading reading) {
    return FavoriteMoment(
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
  }

  static FavoriteMoment palm(PalmReading reading) {
    return FavoriteMoment(
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
  }

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

  static FavoriteMoment astrology({
    required String signId,
    required DateTime at,
    required String signLabel,
    required AstrologyDailyReading reading,
  }) {
    final ref = '$signId-${at.year}-${at.month}-${at.day}';
    return FavoriteMoment(
      id: '${FavoriteMomentSource.astrology.name}:$ref',
      source: FavoriteMomentSource.astrology,
      sourceRef: ref,
      savedAt: DateTime.now(),
      occurredAt: at,
      quote: FavoriteMomentText.firstNonEmpty([
        reading.overall,
        reading.advice,
        reading.innerTheme,
      ]),
      visualLabel: signLabel,
    );
  }
}
