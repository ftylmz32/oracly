import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/dream_record.dart';
import 'package:oracly_new/core/domain/repositories/dream_repository.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/models/dream_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/oracly_ai_service.dart';
import 'package:oracly_new/features/dream/controllers/dream_analysis_controller.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';

class _MemoryDreamRepository implements DreamRepository {
  final List<DreamRecord> records = <DreamRecord>[];

  @override
  Future<List<DreamRecord>> getAll() async => List<DreamRecord>.from(records);

  @override
  Future<DreamRecord?> getById(String id) async {
    for (final record in records) {
      if (record.id == id) return record;
    }
    return null;
  }

  @override
  Future<void> save(DreamRecord record) async {
    records.removeWhere((existing) => existing.id == record.id);
    records.add(record);
  }

  @override
  Future<void> delete(String id) async {
    records.removeWhere((record) => record.id == id);
  }

  @override
  Future<void> sync() async {}
}

class _BlockingDreamAi implements OraclyAiService {
  int dreamCalls = 0;
  final started = Completer<void>();
  final release = Completer<void>();

  @override
  bool get isConfigured => true;

  @override
  bool get visionAvailable => false;

  @override
  bool get allowsLocalFallback => false;

  @override
  Future<AiOutcome<DreamAiAnalysis>> analyzeDream(
    DreamAiContext context,
  ) async {
    dreamCalls += 1;
    if (!started.isCompleted) started.complete();
    await release.future;
    throw StateError('late dream response');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('dispose during organizing delay prevents the Dream AI call', () async {
    final ai = _BlockingDreamAi();
    final controller = DreamAnalysisController(
      DreamExperienceService(
        repository: _MemoryDreamRepository(),
        ai: ai,
      ),
      organizingDelay: const Duration(milliseconds: 1),
    );

    final pending = controller.submit(narrative: 'Bir kapı gördüm.');
    controller.dispose();
    await pending;

    expect(ai.dreamCalls, 0);
  });

  test('reset invalidates an already in-flight Dream response', () async {
    final ai = _BlockingDreamAi();
    final controller = DreamAnalysisController(
      DreamExperienceService(
        repository: _MemoryDreamRepository(),
        ai: ai,
      ),
      organizingDelay: Duration.zero,
    );
    addTearDown(controller.dispose);

    final pending = controller.submit(narrative: 'Bir koridorda yürüdüm.');
    await ai.started.future;
    expect(controller.phase, DreamJourneyPhase.reflecting);

    controller.reset();
    expect(controller.phase, DreamJourneyPhase.entry);
    expect(controller.dream, isNull);
    expect(controller.errorMessage, isNull);

    ai.release.complete();
    await pending;

    expect(controller.phase, DreamJourneyPhase.entry);
    expect(controller.dream, isNull);
    expect(controller.errorMessage, isNull);
  });
}
