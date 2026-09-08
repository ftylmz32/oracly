import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/features/dream/data/dream_entry_draft_store.dart';
import 'package:oracly_new/features/dream/models/dream_entry_context.dart';

void main() {
  group('DreamEntryDraftStore', () {
    test('saves and restores unfinished narrative and context', () async {
      final storage = LocalStorage.ephemeral();
      final store = DreamEntryDraftStore(storage);

      await store.save(
        narrative: 'I was walking through a quiet blue city.',
        chips: {
          DreamEntryChipId.clear,
          DreamEntryChipId.symbols,
        },
        guidedAnswers: {
          DreamGuidedQuestionId.who: 'My sister',
          DreamGuidedQuestionId.feeling: 'Curious',
        },
      );

      final restored = store.load();
      expect(restored, isNotNull);
      expect(restored!.narrative, contains('blue city'));
      expect(restored.chips, contains(DreamEntryChipId.clear));
      expect(restored.chips, contains(DreamEntryChipId.symbols));
      expect(
        restored.guidedAnswers[DreamGuidedQuestionId.who],
        'My sister',
      );
      expect(
        restored.guidedAnswers[DreamGuidedQuestionId.feeling],
        'Curious',
      );
    });

    test('clear removes the draft completely', () async {
      final storage = LocalStorage.ephemeral();
      final store = DreamEntryDraftStore(storage);

      await store.save(
        narrative: 'A dream worth keeping until analysis completes.',
        chips: {DreamEntryChipId.nightmare},
        guidedAnswers: const {},
      );
      expect(store.load(), isNotNull);

      await store.clear();
      expect(store.load(), isNull);
    });

    test('malformed guided payload never blocks entry restore', () async {
      final storage = LocalStorage.ephemeral({
        'dream.entry_draft.narrative.v1': 'The narrative still survives.',
        'dream.entry_draft.guided.v1': '{not-json',
        'dream.entry_draft.chips.v1': <String>['unknown', 'clear'],
      });
      final store = DreamEntryDraftStore(storage);

      final restored = store.load();
      expect(restored, isNotNull);
      expect(restored!.narrative, 'The narrative still survives.');
      expect(restored.chips, {DreamEntryChipId.clear});
      expect(restored.guidedAnswers, isEmpty);
    });
  });
}
