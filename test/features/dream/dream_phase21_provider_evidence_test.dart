/// Dream Phase 2.1 — provider-facing evidence follows the operation language.
/// Real path: DreamExperienceService → DreamInsightBuilder → DreamAiContext →
/// OpenAiPaidRequests.dream. Synthetic narratives; zero provider calls.
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/dream/models/dream_entry_context.dart';
import 'package:oracly_new/features/dream/services/dream_experience_service.dart';

import '../../support/dream_test_owner.dart';
import 'dream_honesty_fakes.dart';
import 'dream_phase21_support.dart';
import 'dream_phase2_support.dart';

void main() {
  tearDown(() => OraclyL10n.bind('tr'));

  test('Case 1 — EN narrative, TR app: EN evidence, no Turkish labels',
      () async {
    const answer = 'Mira  and   Leo, by the lantern';
    final (ctx, _, _) = await send(
      enTold,
      app: 'tr',
      entry: entryWith(DreamGuidedQuestionId.who, answer),
    );
    final payload = payloadOf(ctx);
    expect(payload['language'], 'en');
    expect(payload['emotions'], ['fearful']);
    expect(payload['symbols'], unorderedEquals(['door', 'sea']));
    final narrative = payload['narrative'] as String;
    expect(narrative, contains('\n[Context]\n- I had a nightmare\n'));
    expect(narrative, contains('- Who was in your dream?: $answer'));
    final wire = jsonEncode(payload);
    for (final leak in [
      'Korkulu', 'Kapı', 'Deniz', '[Bağlam]', 'Kabus', 'Rüyanda kimler',
      'display tag',
    ]) {
      expect(wire, isNot(contains(leak)), reason: leak);
    }
  });

  test('Case 2 — RU narrative, EN app: RU evidence, no fake RU catalogue',
      () async {
    const answer = 'У старого дома, где жила бабушка';
    final (ctx, _, _) = await send(
      ruTold,
      app: 'en',
      entry: entryWith(DreamGuidedQuestionId.where, answer),
    );
    final payload = payloadOf(ctx);
    expect(payload['language'], 'ru');
    expect(payload['emotions'], ['испуганный']);
    expect(payload['symbols'], isEmpty);
    final narrative = payload['narrative'] as String;
    expect(narrative, contains('\n[Контекст]\n- Был кошмар\n'));
    expect(narrative, contains('- Помнишь, где это было?: $answer'));
    final wire = jsonEncode(payload);
    for (final leak in [
      'Korkulu', 'fearful', 'Kapı', 'Deniz', '[Context]', 'I had a nightmare',
      'Do you remember', 'Kabus',
    ]) {
      expect(wire, isNot(contains(leak)), reason: leak);
    }
  });

  test('Case 3 — TR narrative, EN app: TR scaffolding, answer byte-faithful',
      () async {
    const answer = 'Annem  ve Leo — "sessizce" bakıyordu';
    final (ctx, repo, _) = await send(
      trTold,
      app: 'en',
      entry: entryWith(DreamGuidedQuestionId.who, answer),
    );
    final payload = payloadOf(ctx);
    expect(payload['language'], 'tr');
    expect(payload['emotions'], ['Korkulu']);
    expect(payload['symbols'], unorderedEquals(['Ev', 'Kapı']));
    final narrative = payload['narrative'] as String;
    expect(narrative, startsWith(trTold));
    expect(narrative, contains('\n[Bağlam]\n- Kabus gördüm\n'));
    expect(narrative, contains('- Rüyanda kimler vardı?: $answer'));
    for (final leak in ['[Context]', 'I had a nightmare', 'Who was in', 'fearful']) {
      expect(narrative, isNot(contains(leak)), reason: leak);
    }
    final stored = (await repo.getAll()).single;
    expect(stored.tags, ['display tag as shown at entry']);
  });

  test('reinterpret reuses the stored entry in the narrative language',
      () async {
    final ai = ScriptedDreamAi.grounded();
    final (_, _, service) = await send(
      trTold,
      app: 'en',
      entry: entryWith(DreamGuidedQuestionId.who, 'Leo'),
      ai: ai,
    );
    final saved = (await service.loadHistory()).single;
    expect(saved.entry?.chips, [DreamEntryChipId.nightmare]);
    OraclyL10n.bind('ru');
    await service.reinterpret(saved);
    final again = ai.contexts.last.narrative;
    expect(again, contains('[Bağlam]\n- Kabus gördüm\n- Rüyanda kimler vardı?: Leo'));
    expect(ai.contexts.last.narrative, ai.contexts.first.narrative);
  });

  test('legacy record without entry keeps its stored tags verbatim', () async {
    final (ctx, _, _) = await send(enTold, app: 'tr');
    expect(ctx.narrative, contains('[Context]\n- display tag as shown at entry'));
  });

  test('no context → no heading; lexicon feeling kept only where written',
      () async {
    OraclyL10n.bind('en');
    final ai = ScriptedDreamAi.grounded();
    await DreamExperienceService(
      repository: MemDreamRepository(),
      owner: testDreamOwner(),
      ai: ai,
    ).analyze(narrative: 'Rüyamda korku ile sessiz bir ev vardı, kapı açıktı.');
    final ctx = ai.contexts.single;
    expect(ctx.language, 'tr');
    expect(ctx.narrative, isNot(contains('[')));
    expect(ctx.emotions, ['Korku']);
  });
}
