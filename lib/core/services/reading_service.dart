/// OR-1170 — Reading creation and history service.
library;

import '../../features/tarot/domain/models/reading_session.dart';
import '../../features/tarot/services/ritual_journal_enricher.dart';
import '../domain/models/ritual_journal_metadata.dart';
import '../domain/models/reading.dart';
import '../domain/repositories/history_repository.dart';
import '../domain/repositories/user_repository.dart';

class ReadingService {
  ReadingService(this._history, this._user);

  final HistoryRepository _history;
  final UserRepository _user;

  Future<ReadingModel> saveReading({
    required int cardIndex,
    required int cardId,
    required String cardName,
    required String cardImageAsset,
    required String spreadType,
    required String aiSummary,
    String deckId = 'rider-waite',
    List<ReadingCardSnapshot> cards = const [],
    String? intention,
    int? shuffleSeed,
    int? durationMs,
    String? sessionId,
    String? userId,
    RitualJournalMetadata? journal,
  }) async {
    final enriched = journal ??
        RitualJournalEnricher.enrich(
          aiSummary: aiSummary,
          cardName: cardName,
          intention: intention,
        );
    final reading = ReadingModel(
      id: sessionId ?? 'reading_${DateTime.now().millisecondsSinceEpoch}',
      cardId: cardId,
      cardIndex: cardIndex,
      cardName: cardName,
      cardImageAsset: cardImageAsset,
      spreadType: spreadType,
      aiSummary: aiSummary,
      createdAt: DateTime.now(),
      deckId: deckId,
      cards: cards,
      intention: intention,
      shuffleSeed: shuffleSeed,
      durationMs: durationMs,
      sessionId: sessionId,
      userId: userId,
      journal: enriched,
    );
    await _history.saveReading(reading);
    await _user.incrementReadings();
    await _user.unlockAchievement('first_reading');
    return reading;
  }

  Future<ReadingModel?> saveFromSession({
    required ReadingSession session,
    required String aiSummary,
    String? existingNote,
  }) async {
    if (session.drawnCards.isEmpty) return null;
    final primary = session.drawnCards.first;
    return saveReading(
      cardIndex: primary.positionIndex,
      cardId: primary.card.id,
      cardName: session.drawnCards.length == 1
          ? primary.card.name
          : '${session.spread.label} · ${primary.card.name}',
      cardImageAsset: primary.card.image,
      spreadType: session.spread.label,
      aiSummary: aiSummary,
      deckId: session.deckId,
      sessionId: session.id,
      userId: session.userId,
      intention: session.intention.text,
      shuffleSeed: session.shuffleSeed,
      durationMs: session.durationMs,
      journal: RitualJournalEnricher.enrich(
        aiSummary: aiSummary,
        cardName: primary.card.name,
        existingNote: existingNote,
        intention: session.intention.text,
      ),
      cards: session.drawnCards
          .map(
            (d) => ReadingCardSnapshot(
              cardId: d.card.id,
              cardName: d.card.name,
              cardImageAsset: d.card.image,
              positionIndex: d.positionIndex,
              positionLabel: d.positionLabel,
              isReversed: d.isReversed,
            ),
          )
          .toList(),
    );
  }

  Future<void> updatePersonalNote({
    required String readingId,
    required String? note,
  }) async {
    final all = await getHistory();
    for (final reading in all) {
      if (reading.id == readingId || reading.sessionId == readingId) {
        await _history.saveReading(
          reading.copyWith(
            journal: reading.journal.copyWith(
              personalNote: note?.trim(),
              clearPersonalNote: note == null || note.trim().isEmpty,
            ),
          ),
        );
        return;
      }
    }
  }

  Future<void> toggleFavorite(String readingId) async {
    final all = await getHistory();
    for (final reading in all) {
      if (reading.id == readingId || reading.sessionId == readingId) {
        await _history.saveReading(
          reading.copyWith(
            journal: reading.journal.copyWith(
              isFavorite: !reading.journal.isFavorite,
            ),
          ),
        );
        return;
      }
    }
  }

  Future<List<ReadingModel>> getHistory() => _history.getReadings();

  Future<ReadingModel?> getById(String id) async {
    final all = await getHistory();
    for (final reading in all) {
      if (reading.id == id || reading.sessionId == id) return reading;
    }
    return null;
  }
}
