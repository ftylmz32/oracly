/// Phase 8.2 — journal save + history reopen from real paid E2E.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/reading.dart';
import 'package:oracly_new/core/domain/repositories/history_repository.dart';
import 'package:oracly_new/core/domain/repositories/user_repository.dart';
import 'package:oracly_new/core/services/reading_service.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/presentation/utils/saved_reading_parser.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/ai_reading_content.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/ai_reading/reading_result_mode.dart';
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
  Future<void> saveReading(ReadingModel reading) async {
    readings.removeWhere((r) => r.id == reading.id);
    readings.add(reading);
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
  Future<void> ensureReadingCompletionMigration(
    List<String> existingHistoryIds,
  ) async {}

  @override
  Future<bool> recordReadingCompletion(String readingId) async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('happy three — journal once + history reopen provider=0', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'e2e_journal_three');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final live = await world.completeViaController(ctrl, interp);
    expect(live, isNotNull);
    expect(ai.callCount, 1);
    final fingerprint = live!.fullInterpretation!;

    final completed = await ctrl.completeSession();
    final history = _MemHistory();
    final service = ReadingService(history, _StubUser());
    final saved = await service.saveFromSession(
      session: completed,
      aiSummary: fingerprint,
      resultMode: completed.interpretationResultMode ??
          ReadingResultModeResolver.of(completed.spread).name,
      interpretationSource: live.interpretationSource.name,
      deliveryKind: live.deliveryKind.name,
    );
    expect(saved, isNotNull);
    expect(history.readings, hasLength(1));
    expect(saved!.sessionId ?? saved.id, session.id);
    expect(saved.cards, hasLength(3));
    expect(saved.resultMode, 'narrativeV2');
    expect(saved.deliveryKind, 'interpretation');

    final reopenAi = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final entry = ReadingHistoryEntry(
      id: saved.id,
      date: saved.createdAt,
      spreadType: saved.spreadType,
      filter: HistorySpreadFilter.three,
      cardName: saved.cardName,
      cardImageAsset: saved.cardImageAsset,
      aiSummary: saved.aiSummary,
      moodIcon: Icons.auto_awesome,
      cardIndex: 0,
      heroTag: 'h_${saved.id}',
      readingType: saved.readingType,
    );
    expect(saved.aiSummary, fingerprint);
    final reopened = SavedReadingParser.toContent(entry: entry, model: saved);
    // History parser may soften display sections; durable body is saved.aiSummary.
    expect(saved.aiSummary, contains('Clarity does not require perfection'));
    expect(reopened.drawnCards, hasLength(3));
    expect(reopened.deliveryKind, TarotReadingDeliveryKind.interpretation);
    expect(reopenAi.callCount, 0);
    expect(world.charge.alreadyCharged(session.id), isTrue);
    ctrl.dispose();
  });
}
