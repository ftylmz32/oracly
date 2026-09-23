/// ReadingSession + ReadingModel → normalized Tarot history (Phase 4C).
library;

import '../../../../core/domain/models/reading.dart';
import '../../../../core/services/history_service.dart';
import '../../domain/models/reading_session.dart';
import '../../domain/repositories/tarot_reading_repository.dart';
import 'tarot_history_legacy_normalize.dart';
import 'tarot_history_normalize_diagnostics.dart';
import 'tarot_history_session_normalize.dart';
import 'tarot_historical_models.dart';

class TarotHistorySourceAdapter {
  TarotHistorySourceAdapter({
    required this.history,
    required this.tarotRepository,
  });

  final HistoryService history;
  final TarotReadingRepository tarotRepository;

  Future<
    ({
      List<TarotHistoricalReadingRecord> readings,
      Set<String> liveTarotSourceIds,
      TarotHistoryNormalizeDiagnostics diagnostics,
    })
  >
  load({required String? currentOwnerId}) async {
    final models = await history.getAll();
    final sessions = await tarotRepository.loadAllSessions();
    final linkedIds = <String>{};
    final liveTarotSourceIds = <String>{};
    final records = <TarotHistoricalReadingRecord>[];
    var diag = const TarotHistoryNormalizeDiagnostics();

    for (final session in sessions) {
      if (!TarotHistorySessionNormalize.isEligible(session)) continue;
      final linked = TarotHistorySessionNormalize.pickEnrichment(
        session,
        models,
      );
      final result = TarotHistorySessionNormalize.normalize(
        session: session,
        linked: linked,
        currentOwnerId: currentOwnerId,
      );
      diag = diag + result.diag;
      linkedIds.addAll(result.linkedReadingIds);
      if (result.record != null) {
        records.add(result.record!);
        liveTarotSourceIds.addAll(result.liveSourceIds);
      }
    }

    for (final model in models) {
      if (linkedIds.contains(model.id)) continue;
      if (_linkedViaSession(model, sessions, linkedIds)) continue;
      final result = TarotHistoryLegacyNormalize.normalize(
        reading: model,
        currentOwnerId: currentOwnerId,
      );
      diag = diag + result.diag;
      if (result.record != null) {
        records.add(result.record!);
        if (model.id.trim().isNotEmpty) {
          liveTarotSourceIds.add(model.id.trim());
        }
      }
    }

    records.sort((a, b) {
      final byTime = b.occurredAt.compareTo(a.occurredAt);
      if (byTime != 0) return byTime;
      return a.readingId.compareTo(b.readingId);
    });

    return (
      readings: List<TarotHistoricalReadingRecord>.unmodifiable(records),
      liveTarotSourceIds: Set<String>.unmodifiable(liveTarotSourceIds),
      diagnostics: diag,
    );
  }

  bool _linkedViaSession(
    ReadingModel model,
    List<ReadingSession> sessions,
    Set<String> linkedIds,
  ) {
    final sid = model.sessionId;
    for (final s in sessions) {
      if (!TarotHistorySessionNormalize.isEligible(s)) continue;
      if (s.id == model.id || (sid != null && s.id == sid)) {
        if (linkedIds.contains(model.id)) return true;
        if (sid != null && linkedIds.contains(sid)) return true;
        return true;
      }
    }
    return false;
  }
}
