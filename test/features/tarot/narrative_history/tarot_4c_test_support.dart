/// Shared fixtures for Phase 4C narrative history adapter tests.
library;

import 'dart:convert';

import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_birth_chart_repository.dart';
import 'package:oracly_new/core/data/repositories/local_dream_repository.dart';
import 'package:oracly_new/core/data/repositories/mock_history_repository.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/memory/oracly_memory.dart';
import 'package:oracly_new/core/memory/oracly_memory_store.dart';
import 'package:oracly_new/core/services/history_service.dart';
import 'package:oracly_new/features/birth_chart/data/birth_chart_record_mapper.dart';
import 'package:oracly_new/features/birth_chart/models/birth_chart.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/birth_chart/models/chart_insight.dart';
import 'package:oracly_new/features/birth_chart/services/natal_chart_calculator.dart';
import 'package:oracly_new/features/premium/data/soul_mate_interpretation_catalogue.dart';
import 'package:oracly_new/features/premium/data/soul_mate_result_store.dart';
import 'package:oracly_new/features/premium/models/soul_mate_saved_result.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/history/tarot_history_deletion_service.dart';
import 'package:oracly_new/features/tarot/models/tarot_card.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_snapshot_loader.dart';

const tarotCard0 = TarotCard(
  id: 0,
  name: 'The Fool',
  image: 'fool.png',
  arcana: TarotArcana.major,
  suit: TarotSuit.none,
  number: 0,
  summary: 's',
  meaning: 'm',
  reversedMeaning: 'r',
  keywords: ['k'],
);

ReadingSession completedSession({
  required String id,
  String? userId,
  DateTime? at,
  String intention = 'Bu kararı vermeli miyim?',
  String? topic = 'career',
  bool reversed = false,
  String? positionKey = 'sign',
  int positionIndex = 0,
  String? interpretation = 'Sakin bir yorum.',
}) {
  final stamp = at ?? DateTime.utc(2026, 8, 10, 12);
  return ReadingSession(
    id: id,
    deckId: 'rider-waite',
    userId: userId,
    spread: TarotSpreadType.single,
    intention: TarotIntention(text: intention, topic: topic),
    shuffleSeed: 1,
    startedAt: stamp,
    completedAt: stamp.add(const Duration(minutes: 2)),
    status: ReadingSessionStatus.completed,
    drawnCards: [
      TarotDrawnCard(
        card: tarotCard0,
        positionIndex: positionIndex,
        isReversed: reversed,
        positionKey: positionKey,
      ),
    ],
    interpretation: interpretation,
  );
}

ReadingModel journalReading({
  required String id,
  String? sessionId,
  String? userId,
  DateTime? at,
  String spreadType = 'Tek Kart',
  List<ReadingCardSnapshot> cards = const [],
  int cardId = 0,
  int cardIndex = 0,
  String? intention,
  String? readingType,
  String aiSummary = 'Journal yorum.',
}) {
  return ReadingModel(
    id: id,
    cardId: cardId,
    cardName: 'The Fool',
    cardImageAsset: 'fool.png',
    spreadType: spreadType,
    aiSummary: aiSummary,
    createdAt: at ?? DateTime.utc(2026, 8, 10, 12),
    cards: cards,
    intention: intention,
    readingType: readingType,
    sessionId: sessionId,
    userId: userId,
  );
}

OraclyMemory readingMemory({
  required String sourceId,
  required OraclyReadingType type,
  String summary = 'Bag summary',
  List<String> themes = const ['karar'],
  DateTime? at,
}) {
  return OraclyMemory(
    id: 'reading:${type.name}:$sourceId',
    kind: OraclyMemoryKind.reading,
    source: OraclyMemorySource(
      id: sourceId,
      type: type,
      occurredAt: at ?? DateTime.utc(2026, 8, 10),
    ),
    summary: summary,
    themes: themes,
    confidence: 0.7,
  );
}

Future<void> setOwner(LocalStorage storage, String? ownerId) async {
  if (ownerId == null) {
    await storage.remove(UserLocalDataIsolation.ownerKey);
  } else {
    await storage.setString(UserLocalDataIsolation.ownerKey, ownerId);
  }
}

Future<void> writeSoulMateMeta(
  LocalStorage storage, {
  required String id,
  required bool authoritative,
}) async {
  final meta = SoulMateSavedResult(
    id: id,
    createdAt: DateTime.utc(2026, 3, 1),
    name: 'N',
    birthDate: DateTime.utc(2000, 1, 1),
    portraitPath: '/tmp/p.jpg',
    parts: SoulMateReadingParts(
      energy: 'e',
      attraction: 'a',
      dynamics: 'd',
      feeling: 'f',
      yourSide: 'y',
      authoritative: authoritative,
    ),
  );
  await storage.setString(
    SoulMateResultStore.metaKey,
    jsonEncode(meta.toJson()),
  );
}

BirthChart journeyReadyChart(String id) {
  final base = const NatalChartCalculator().calculate(
    BirthProfile(
      birthDate: DateTime(1990, 3, 25),
      birthPlace: 'Ankara',
      birthTimeKnown: false,
    ),
  );
  final json = Map<String, dynamic>.from(base.toJson());
  json['id'] = id;
  json['insights'] = [
    {
      'kind': ChartInsightKind.lifeThemes.name,
      'title': 'Tema',
      'body': 'Yeterli gövde metni.',
    },
  ];
  return BirthChart.fromJson(json);
}

Future<void> saveJourneyChart(LocalStorage storage, String id) async {
  // Do not seed ownerKey — null currentOwnerId + set local owner privacyBlocks.
  final owner = storage.getString(UserLocalDataIsolation.ownerKey);
  final record = BirthChartRecordMapper.toRecord(journeyReadyChart(id));
  final stamped =
      (owner == null || owner.isEmpty) ? record : record.copyWith(ownerId: owner);
  await storage.setString(
    LocalBirthChartRepository.storageKey,
    jsonEncode(stamped.toJson()),
  );
}

class Phase4cHarness {
  Phase4cHarness(this.storage)
    : readings = MockHistoryRepository(storage),
      tarot = TarotReadingRepositoryImpl.fromStorage(storage),
      memory = OraclyMemoryStore(storage),
      dreams = LocalDreamRepository(storage) {
    history = HistoryService(readings);
  }

  final LocalStorage storage;
  final MockHistoryRepository readings;
  late final HistoryService history;
  final TarotReadingRepositoryImpl tarot;
  final OraclyMemoryStore memory;
  final LocalDreamRepository dreams;

  /// Binds to the current canonical owner key (may be null).
  LocalBirthChartRepository get birthCharts => LocalBirthChartRepository(
        storage,
        ownerId: storage.getString(UserLocalDataIsolation.ownerKey),
      );

  TarotHistoricalSnapshotLoader loader() => TarotHistoricalSnapshotLoader(
    storage: storage,
    history: history,
    tarotRepository: tarot,
    memory: memory,
    dreams: dreams,
    birthCharts: birthCharts,
  );

  TarotHistoryDeletionService deletion() => TarotHistoryDeletionService(
    history: history,
    tarotRepository: tarot,
    memory: memory,
  );
}
