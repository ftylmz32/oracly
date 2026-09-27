// Dream Phase 3 — service + controller fail closed before provider/storage;
// safety state is ephemeral and cleared on reset and owner switch.
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/domain/models/dream_record.dart';
import 'package:oracly_new/features/dream/controllers/dream_analysis_controller.dart';
import 'package:oracly_new/features/dream/data/dream_record_mapper.dart';
import 'package:oracly_new/features/dream/models/dream_entry_context.dart';
import 'package:oracly_new/features/dream/models/dream_entry_selection.dart';
import 'package:oracly_new/features/dream/providers/dream_providers.dart';
import 'package:oracly_new/features/dream/safety/dream_safety_concern.dart';

import 'dream_phase1_support.dart';

const _blocked = <String, DreamSafetyConcern>{
  'Uyandım ve şimdi kendimi öldürmek istiyorum.': DreamSafetyConcern.crisis,
  'I can\'t keep myself safe right now.': DreamSafetyConcern.acuteDistress,
  'Этот сон напомнил мне о насилии, которое на самом деле было со мной в детстве.':
      DreamSafetyConcern.trauma,
  'This dream proves aliens are communicating with me.':
      DreamSafetyConcern.delusion,
  'У меня психоз из-за этого сна?': DreamSafetyConcern.diagnosis,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('direct analyze fails closed: provider 0, dream/memory/version rows 0',
      () async {
    final env = await DreamPhase1Env.open();
    final service = env.service();
    for (final entry in _blocked.entries) {
      await expectLater(
        service.analyze(narrative: entry.key),
        throwsA(isA<DreamSafetyException>()
            .having((e) => e.concern, 'concern', entry.value)),
      );
    }
    await expectLater(
      service.analyze(
        narrative: 'Rüyamda sessiz bir bahçede yürüyordum.',
        entry: DreamEntrySelection.of(
          chips: {DreamEntryChipId.nightmare},
          guided: {DreamGuidedQuestionId.values.first: 'Şimdi ölmek istiyorum'},
        ),
      ),
      throwsA(isA<DreamSafetyException>()),
    );
    expect(env.ai.calls, 0);
    expect(env.persistedDreamState(), '##');
  });

  test('controller routes each concern to the safety state with no reading',
      () async {
    final env = await DreamPhase1Env.open();
    final controller = DreamAnalysisController(
      env.service(),
      organizingDelay: Duration.zero,
    );
    for (final entry in _blocked.entries) {
      await controller.submit(narrative: entry.key);
      expect(controller.phase, DreamJourneyPhase.safety);
      expect(controller.safety?.concern, entry.value);
      expect(controller.dream, isNull);
      expect(controller.errorMessage, isNull);
    }
    expect(env.ai.calls, 0);
    expect(env.persistedDreamState(), '##');
    controller.reset();
    expect(controller.phase, DreamJourneyPhase.entry);
    expect(controller.safety, isNull);
  });

  test('legacy sensitive record: reinterpret shows safety, never mutates',
      () async {
    final env = await DreamPhase1Env.open();
    for (final record in [
      DreamRecord(
        id: 'legacy-crisis',
        text: 'I want to kill myself now.',
        analysis: 'An older reflection.',
        createdAt: DateTime.utc(2026, 1, 2),
      ),
      DreamRecord(
        id: 'legacy-tag',
        text: 'A quiet garden with a closed gate.',
        analysis: 'An older reflection.',
        createdAt: DateTime.utc(2026, 1, 3),
        tags: const ['On waking: I am in immediate danger'],
      ),
    ]) {
      await env.repo.save(record);
      final before = env.persistedDreamState();
      final controller = DreamAnalysisController(env.service());
      await controller.openSaved(DreamRecordMapper.fromRecord(record));
      expect(controller.phase, DreamJourneyPhase.complete);
      await controller.reinterpret();
      expect(controller.phase, DreamJourneyPhase.safety);
      expect(controller.lastVersionAdded, isFalse);
      expect(env.persistedDreamState(), before);
      expect(env.versionsRaw, isNull);
    }
    expect(env.ai.calls, 0);
  });

  test('owner switch rebuilds the controller without the safety state',
      () async {
    final env = await DreamPhase1Env.open();
    final container = ProviderContainer(
      overrides: [dreamExperienceServiceProvider.overrideWithValue(env.service())],
    );
    addTearDown(container.dispose);
    final first = container.read(dreamAnalysisControllerProvider);
    first.presentSafety(
      DreamSafetyConcern.crisis,
      narrative: 'I want to kill myself now.',
    );
    expect(first.phase, DreamJourneyPhase.safety);
    await env.switchTo('owner-b');
    final next = container.read(dreamAnalysisControllerProvider);
    expect(identical(next, first), isFalse);
    expect(next.phase, DreamJourneyPhase.entry);
    expect(next.safety, isNull);
  });
}
