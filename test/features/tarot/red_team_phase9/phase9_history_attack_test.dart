/// Phase 9 — history delete-while-reopen / corrupt ReadingModel / parser.
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
import 'package:oracly_new/features/tarot/presentation/widgets/reading_history/reading_history_data.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import '../e2e/tarot_e2e_harness.dart';

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
  Future<void> ensureReadingCompletionMigration(List<String> ids) async {}
  @override
  Future<bool> recordReadingCompletion(String readingId) async => true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('delete while reopen model — parser no crash, no provider', () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'p9_hist_del');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final live = await world.completeViaController(ctrl, interp);
    final completed = await ctrl.completeSession();
    final history = _MemHistory();
    final service = ReadingService(history, _StubUser());
    final saved = await service.saveFromSession(
      session: completed,
      aiSummary: live!.fullInterpretation!,
      resultMode: 'narrativeV2',
      interpretationSource: live.interpretationSource.name,
      deliveryKind: live.deliveryKind.name,
    );
    expect(saved, isNotNull);
    final entry = ReadingHistoryEntry(
      id: saved!.id,
      date: saved.createdAt,
      spreadType: saved.spreadType,
      filter: HistorySpreadFilter.three,
      cardName: saved.cardName,
      cardImageAsset: saved.cardImageAsset,
      aiSummary: saved.aiSummary,
      moodIcon: Icons.auto_awesome,
      cardIndex: 0,
      heroTag: 'h_${saved.id}',
    );
    await history.deleteReading(saved.id);
    expect(history.readings, isEmpty);
    final content = SavedReadingParser.toContent(entry: entry, model: saved);
    expect(content.fullInterpretation, isNotNull);
    expect(ai.callCount, 1);
    ctrl.dispose();
  });

  test('corrupt ReadingModel fields — parser fail-soft', () {
    final model = ReadingModel(
      id: 'corrupt',
      cardId: -1,
      cardName: '',
      cardImageAsset: '',
      spreadType: 'notASpread',
      aiSummary: '',
      createdAt: DateTime.utc(2026, 9, 25),
      resultMode: '???',
      interpretationSource: 'bogus',
      deliveryKind: 'nope',
    );
    final entry = ReadingHistoryEntry(
      id: model.id,
      date: model.createdAt,
      spreadType: model.spreadType,
      filter: HistorySpreadFilter.three,
      cardName: model.cardName,
      cardImageAsset: model.cardImageAsset,
      aiSummary: model.aiSummary,
      moodIcon: Icons.help_outline,
      cardIndex: 0,
      heroTag: 'h_corrupt',
    );
    expect(SavedReadingParser.toContent(entry: entry, model: model), isNotNull);
  });
}
