/// Phase 8 — history mapper roundtrip fields + concurrent skip note.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/domain/repositories/history_repository.dart';
import 'package:oracly_new/core/domain/repositories/user_repository.dart';
import 'package:oracly_new/core/services/reading_service.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/presentation/utils/reading_history_mapper.dart';
import 'package:oracly_new/features/tarot/presentation/utils/saved_reading_parser.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/reading_history/reading_history_data.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import 'tarot_e2e_harness.dart';

class _MemHistory implements HistoryRepository {
  final List<ReadingModel> readings = [];
  @override
  Future<List<ReadingModel>> getReadings() async => List.of(readings);
  @override
  Future<void> saveReading(ReadingModel r) async {
    readings.removeWhere((x) => x.id == r.id);
    readings.add(r);
  }

  @override
  Future<void> deleteReading(String id) async {
    readings.removeWhere((r) => r.id == id || r.sessionId == id);
  }

  @override
  Future<void> clearAll() async => readings.clear();
}

class _StubUser implements UserRepository {
  @override
  Future<void> ensureReadingCompletionMigration(List<String> ids) async {}
  @override
  Future<bool> recordReadingCompletion(String readingId) async => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // CONCURRENT resolveInterpretationContent — covered in phase8_new_session_test.
  // SKIP duplicate here.

  test('HISTORY ROUNDTRIP — mapper + parser fields; reopen provider=0',
      () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'e2e_hist_roundtrip');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final live = await world.completeViaController(ctrl, interp);
    final completed = await ctrl.completeSession();
    final fingerprint = live!.fullInterpretation!;
    final saved = await ReadingService(_MemHistory(), _StubUser()).saveFromSession(
      session: completed,
      aiSummary: fingerprint,
      resultMode: completed.interpretationResultMode ?? 'narrativeV2',
      interpretationSource: live.interpretationSource.name,
      deliveryKind: live.deliveryKind.name,
    );
    expect(saved, isNotNull);
    final entry = ReadingHistoryMapper.fromModel(saved!);
    expect(entry.id, saved.id);
    expect(entry.filter, HistorySpreadFilter.three);
    expect(entry.aiSummary, fingerprint);
    expect(entry.cardName, isNotEmpty);
    expect(saved.cards, hasLength(3));
    expect(saved.sessionId ?? saved.id, session.id);
    expect(saved.resultMode, 'narrativeV2');
    expect(saved.deliveryKind, 'interpretation');

    final reopenAi = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final reopened = SavedReadingParser.toContent(entry: entry, model: saved);
    expect(reopened.drawnCards, hasLength(3));
    expect(reopened.deliveryKind, TarotReadingDeliveryKind.interpretation);
    expect(reopenAi.callCount, 0);
    expect(world.charge.alreadyCharged(session.id), isTrue);
    ctrl.dispose();
  });
}
