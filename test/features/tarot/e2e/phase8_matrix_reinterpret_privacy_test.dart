/// Phase 8 — reinterpret contract / first reading / intention privacy.
/// REAL PROVIDER CALLS = 0. Production unchanged.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/reading_version/models/reading_version_kind.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_payload.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_service.dart';
import 'package:oracly_new/core/reading_version/services/reading_version_store.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/economy/tarot_economy.dart';
import 'package:oracly_new/features/tarot/first_session/tarot_first_reading.dart';
import 'package:oracly_new/features/tarot/history/tarot_history_privacy.dart';

import '../narrative_live/phase6f1_billing_boundary_test.dart'
    show threeContrastSession;
import '../narrative_live/phase6f_live_support.dart';
import 'tarot_e2e_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('USER REINTERPRET — provider ok, second charge 0; versions', () async {
    final world = await TarotE2eWorld.create();
    final body = cloneSolThreeForEmptySession();
    final mutant = cloneSolThreeForEmptySession();
    mutant['summary'] = '${mutant['summary']} A quieter second look.';
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(body),
      AiOutcome.success(mutant),
      AiOutcome.success(mutant),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    final session = threeContrastSession(id: 'e2e_reinterpret');
    await ctrl.updateSession(
      session.copyWith(
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
      ),
    );
    final paid = await world.completeViaController(ctrl, interp);
    expect(world.charge.alreadyCharged(session.id), isTrue);
    final original = paid!.fullInterpretation!;
    await ctrl.updateSession(ctrl.session!.copyWith(interpretation: original));
    final balanceAfterPaid = world.authority.balance;

    // _reinterpretWithoutCharge contract: forceRefresh, no TarotReadingCharge.
    final revised = await ctrl.resolveInterpretationContent(forceRefresh: true);
    expect(revised.fullInterpretation, isNot(original));
    expect(world.charge.alreadyCharged(session.id), isTrue);
    expect(world.authority.balance, balanceAfterPaid);
    expect(ai.callCount, 2);

    final versions = ReadingVersionService(ReadingVersionStore(world.storage));
    await versions.seedOriginal(
      rootId: session.id,
      kind: ReadingVersionKind.tarot,
      data: ReadingVersionPayload.tarot(original),
    );
    final same = await versions.tryAppendRevision(
      rootId: session.id,
      kind: ReadingVersionKind.tarot,
      data: ReadingVersionPayload.tarot(original),
    );
    expect(same.added, isFalse);
    final changed = await versions.tryAppendRevision(
      rootId: session.id,
      kind: ReadingVersionKind.tarot,
      data: ReadingVersionPayload.tarot(revised.fullInterpretation!),
    );
    expect(changed.added, isTrue);
    expect(changed.group.entries, hasLength(2));
    ctrl.dispose();
  });

  test('REINTERPRET safety — not saved as version; original preserved',
      () async {
    final world = await TarotE2eWorld.create();
    final ai = ScriptedNarrativeAi([
      AiOutcome.success(cloneSolThreeForEmptySession()),
    ]);
    final interp = world.interpretation(ai, world.newCache());
    final ctrl = world.controller(interp);
    const prior = 'prior paid body must remain';
    final base = threeContrastSession(id: 'e2e_reint_safety');
    await ctrl.updateSession(
      ReadingSession(
        id: base.id,
        deckId: base.deckId,
        spread: base.spread,
        intention: const TarotIntention(text: 'Intihar etmeyi düşünüyorum'),
        shuffleSeed: base.shuffleSeed,
        startedAt: base.startedAt,
        drawnCards: base.drawnCards,
        status: ReadingSessionStatus.inProgress,
        flowStep: ReadingFlowStep.reading,
        interpretation: prior,
      ),
    );
    final content = await ctrl.resolveInterpretationContent(forceRefresh: true);
    expect(content.isSafetyResponse, isTrue);
    expect(ctrl.session!.interpretation, prior);
    expect(ai.callCount, 0);
    expect(world.charge.alreadyCharged(base.id), isFalse);
    ctrl.dispose();
  });

  test('FIRST READING shortcut — free single spread', () {
    expect(TarotFirstReading.spread, TarotSpreadType.single);
    expect(TarotEconomy.isFree(TarotFirstReading.spread), isTrue);
    expect(TarotEconomy.costFor(TarotFirstReading.spread), isNull);
  });

  test('CUSTOM INTENTION + TOPIC — privacy clip / topic only', () {
    expect(
      TarotHistoryPrivacy.questionSummary('Should I change jobs this year?'),
      isNotNull,
    );
    expect(
      TarotHistoryPrivacy.persistTopic('career', 'Should I change jobs?'),
      'career',
    );
    expect(
      TarotHistoryPrivacy.persistTopic(
        'Should I change jobs this year?',
        'Should I change jobs this year?',
      ),
      isNull,
    );
    expect(
      TarotHistoryPrivacy.questionSummary('sk-abc123 Bearer secret token'),
      isNull,
    );
  });
}
