/// Dream Phase 2.1 — request identity follows the final provider evidence.
/// Real service path; synthetic inputs; zero provider calls.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/ai/production/ai_request_exception.dart';
import 'package:oracly_new/features/ai/production/contexts/reading_ai_context.dart';
import 'package:oracly_new/features/ai/production/dream_request_identity.dart';
import 'package:oracly_new/features/dream/models/dream.dart';
import 'package:oracly_new/features/dream/models/dream_emotion.dart';
import 'package:oracly_new/features/dream/models/dream_entry_context.dart';
import 'package:oracly_new/features/dream/models/dream_symbol.dart';
import 'package:oracly_new/features/dream/services/dream_provider_evidence.dart';
import 'package:oracly_new/features/gems/services/paid_ai_operation_binder.dart';

import 'dream_phase21_support.dart';
import 'dream_phase2_support.dart';

String fp(DreamAiContext c) => DreamRequestIdentity.fingerprint(c);

Future<DreamAiContext> ctx({
  String told = enTold,
  String app = 'tr',
  DreamEmotionId emotion = DreamEmotionId.fearful,
  DreamEntryChipId chip = DreamEntryChipId.nightmare,
  String answer = 'Mira and Leo',
}) async {
  final (context, _, _) = await send(
    told,
    app: app,
    chips: [emotion],
    entry: entryWith(DreamGuidedQuestionId.who, answer, chip: chip),
  );
  return context;
}

void main() {
  tearDown(() => OraclyL10n.bind('tr'));

  test('exact same semantic Dream → same identity and replay key', () async {
    final a = await ctx();
    final b = await ctx();
    expect(fp(a), fp(b));
    expect(payloadOf(a), payloadOf(b));
  });

  test('cosmetic casing / whitespace in the guided answer is stable',
      () async {
    expect(fp(await ctx(answer: '  MIRA   and leo ')), fp(await ctx()));
  });

  test('app locale alone does not change a detected-language request',
      () async {
    expect(fp(await ctx(app: 'ru')), fp(await ctx(app: 'tr')));
  });

  test('semantic changes → new identity', () async {
    final base = fp(await ctx());
    const unknown = 'Mira, Leo, 12:30.';
    final changed = {
      'language': fp(await ctx(told: unknown, app: 'en')) !=
          fp(await ctx(told: unknown, app: 'ru')),
      'emotion': fp(await ctx(emotion: DreamEmotionId.peaceful)) != base,
      'chip': fp(await ctx(chip: DreamEntryChipId.clear)) != base,
      'guided answer': fp(await ctx(answer: 'Mira alone')) != base,
    };
    expect(changed.values.every((v) => v), isTrue, reason: '$changed');
  });

  test('symbol evidence change → new identity (same narrative)', () {
    DreamUnderstanding with_(List<DreamSymbol> symbols) => DreamUnderstanding(
          symbols: symbols,
          emotions: const [],
          locations: const [],
          relationships: const [],
          recurringElements: const [],
          summary: '',
        );
    final dream = Dream(id: 'd', narrative: enTold, recordedAt: DateTime(2026));
    const door = DreamSymbol(token: 'door', label: 'Kapı', kind: DreamSymbolKind.object);
    const sea = DreamSymbol(token: 'sea', label: 'Deniz', kind: DreamSymbolKind.place);
    DreamAiContext build(List<DreamSymbol> s) => DreamProviderEvidence.context(
          dream: dream,
          understanding: with_(s),
          language: 'en',
        );
    expect(build([door]).symbols, ['door']);
    expect(fp(build([door])), isNot(fp(build([door, sea]))));
  });

  test('paid binder keeps the billing id and appends the semantic digest',
      () async {
    final a = await ctx();
    final b = await ctx(emotion: DreamEmotionId.peaceful);
    final keys = await PaidAiOperationBinder.runWithKey('or-dream-x', () async {
      String? key(DreamAiContext c) =>
          DreamRequestIdentity.idempotencyKey(DreamRequestIdentity.fingerprint(c));
      return [key(a), key(a), key(b)];
    });
    expect(keys[0], matches(RegExp(r'^or-dream-x:ds-[0-9a-f]{32}$')));
    expect(keys[1], keys[0]);
    expect(keys[2], isNot(keys[0]));
  });

  // Phase 4B: an ungrounded reply is an invalid response — it is no longer
  // stored as a local-only reading.
  test('unknown language → app language; ungrounded reply fails closed',
      () async {
    final ai = ScriptedDreamAi(phase2AllRejected);
    await expectLater(
      send('Mira, Leo, 12:30.', app: 'ru', ai: ai),
      throwsA(isA<AiRequestException>().having(
        (e) => e.failure.kind,
        'kind',
        AiFailureKind.invalidResponse,
      )),
    );
    expect(ai.contexts.single.language, 'ru');
  });
}
