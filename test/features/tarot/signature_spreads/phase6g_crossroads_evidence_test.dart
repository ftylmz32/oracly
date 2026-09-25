/// Phase 6G — Crossroads internal Narrative Evidence / serializer / cache.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_bridge.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_builder.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_input.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_position_edge_provider.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantic_resolver.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_cache_identity.dart';
import 'package:oracly_new/features/tarot/narrative/prompt/narrative_tarot_prompt_serializer.dart';
import 'package:oracly_new/features/tarot/signature_spreads/narrative_evidence_strategy_dispatch.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_narrative_edge_provider.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_narrative_spread_resolver.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_crossroads_edges.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_evaluator.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_input.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_status.dart';

final _ritualByCanon = <String, int>{
  for (var i = 0; i < 78; i++) OraclyTarotBridge.byRitualId(i)!.id: i,
};

NarrativeEvidenceInput _crossroadsInput({
  String? question = 'Should I accept this offer?',
}) {
  final ids = OraclyTarotDeck.expectedIds.take(5).toList();
  const keys = ['option_a', 'option_b', 'tension', 'counsel', 'direction'];
  return NarrativeEvidenceInput(
    sessionId: '6g_sess',
    readingId: '6g_read',
    languageCode: 'en',
    questionRaw: question,
    spreadType: TarotSpreadType.crossroads,
    cards: [
      for (var i = 0; i < 5; i++)
        NarrativeEvidenceCardInput(
          canonicalCardId: ids[i],
          ritualCardId: _ritualByCanon[ids[i]]!,
          isReversed: false,
          positionKey: keys[i],
          positionIndex: i,
        ),
    ],
  );
}

void main() {
  const sigResolver = SignatureNarrativeSpreadResolver();
  const sigEdges = SignatureNarrativeEdgeProvider();
  const classicalEdges = ClassicalPositionEdgeProvider();

  test('1–2 Crossroads semantic id is signature.crossroads, not fiveCard', () {
    final spread = sigResolver.resolve(TarotSpreadType.crossroads);
    expect(spread.spreadId, 'signature.crossroads');
    expect(spread.spreadId, isNot('classical.fiveCard'));
    expect(spread.legacyTypeName, 'crossroads');
  });

  test('3 Signature resolver + Signature edge provider valid', () {
    final spread = sigResolver.resolve(TarotSpreadType.crossroads);
    final edges = sigEdges.edgesFor(spread);
    expect(edges, hasLength(4));
  });

  test('4 Signature resolver + Classical provider fails closed', () {
    final spread = sigResolver.resolve(TarotSpreadType.crossroads);
    expect(() => classicalEdges.edgesFor(spread), throwsA(isA<ArgumentError>()));
  });

  test('5 Classical resolver + Signature provider fails closed', () {
    final five = ClassicalSpreadSemantics.byLegacyTypeName('fiveCard');
    expect(() => sigEdges.edgesFor(five), throwsA(isA<ArgumentError>()));
  });

  test('6–7 Crossroads Evidence via Signature path + authoritative edges', () {
    final strategy =
        NarrativeEvidenceStrategyDispatch.forSpread(TarotSpreadType.crossroads);
    final req = NarrativeEvidenceBuilder.build(
      _crossroadsInput(),
      resolver: strategy.resolver,
      edgeProvider: strategy.edgeProvider,
    );
    expect(req.spread.spreadId, 'signature.crossroads');
    expect(req.cards, hasLength(5));
    expect(
      [for (final c in req.cards) c.positionKey],
      ['option_a', 'option_b', 'tension', 'counsel', 'direction'],
    );
    final edges = sigEdges.edgesFor(req.spread);
    expect(edges, hasLength(kSignatureCrossroadsEdges.length));
    for (var i = 0; i < edges.length; i++) {
      expect(edges[i].fromPositionKey, kSignatureCrossroadsEdges[i].fromPositionKey);
      expect(edges[i].toPositionKey, kSignatureCrossroadsEdges[i].toPositionKey);
      expect(edges[i].edgeKind, kSignatureCrossroadsEdges[i].edgeKind);
      expect(edges[i].directed, kSignatureCrossroadsEdges[i].directed);
    }
    for (final rel in req.relationships) {
      expect(rel.leftCardId, isNotEmpty);
      expect(rel.rightCardId, isNotEmpty);
    }
  });

  test('8–10 serialize + model spread id + cache ≠ fiveCard', () {
    final strategy =
        NarrativeEvidenceStrategyDispatch.forSpread(TarotSpreadType.crossroads);
    final cross = NarrativeEvidenceBuilder.build(
      _crossroadsInput(),
      resolver: strategy.resolver,
      edgeProvider: strategy.edgeProvider,
    );
    final prompt = NarrativeTarotPromptSerializer.serialize(cross);
    expect(prompt.spread.spreadId, 'signature.crossroads');
    expect(prompt.spread.spreadId, isNot(contains('fiveCard')));

    final fiveIds = OraclyTarotDeck.expectedIds.take(5).toList();
    final fiveDef = ClassicalSpreadSemantics.byLegacyTypeName('fiveCard');
    final five = NarrativeEvidenceBuilder.build(
      NarrativeEvidenceInput(
        sessionId: '6g_sess',
        readingId: '6g_read',
        languageCode: 'en',
        questionRaw: 'Should I accept this offer?',
        spreadType: TarotSpreadType.fiveCard,
        cards: [
          for (var i = 0; i < 5; i++)
            NarrativeEvidenceCardInput(
              canonicalCardId: fiveIds[i],
              ritualCardId: _ritualByCanon[fiveIds[i]]!,
              isReversed: false,
              positionKey: fiveDef.positions[i].positionKey,
              positionIndex: fiveDef.positions[i].index,
            ),
        ],
      ),
    );
    expect(five.spread.spreadId, 'classical.fiveCard');
    expect(
      NarrativeTarotCacheIdentity.keyFor(cross),
      isNot(NarrativeTarotCacheIdentity.keyFor(five)),
    );
  });

  test('20 unsupported relationship question fails closed', () {
    final shadow = SignatureSpreadShadowEvaluator.evaluate(
      input: SignatureSpreadShadowInput(
        sessionId: 's',
        readingId: 'r',
        languageCode: 'en',
        spreadType: TarotSpreadType.crossroads,
        questionRaw: 'How is this relationship evolving?',
        cards: [
          for (var i = 0; i < 5; i++)
            SignatureSpreadShadowCard(
              ritualCardId: i,
              isReversed: false,
              positionIndex: i,
            ),
        ],
      ),
    );
    expect(shadow.ok, isFalse);
    expect(shadow.classicalRequest, isNull);
  });

  test('default Classical builder never aliases Crossroads to fiveCard', () {
    expect(
      () => NarrativeEvidenceBuilder.build(_crossroadsInput()),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('dispatch selects Signature only for Crossroads', () {
    expect(
      NarrativeEvidenceStrategyDispatch.forSpread(TarotSpreadType.crossroads)
          .resolver,
      isA<SignatureNarrativeSpreadResolver>(),
    );
    expect(
      NarrativeEvidenceStrategyDispatch.forSpread(TarotSpreadType.fiveCard)
          .resolver,
      isA<ClassicalSpreadSemanticResolver>(),
    );
  });

  test('shadow path builds Signature Evidence + history statuses', () {
    final ids = OraclyTarotDeck.expectedIds.take(5).toList();
    final shadow = SignatureSpreadShadowEvaluator.evaluate(
      input: SignatureSpreadShadowInput(
        sessionId: 's',
        readingId: 'r',
        languageCode: 'en',
        spreadType: TarotSpreadType.crossroads,
        questionRaw: 'Should I accept this offer?',
        cards: [
          for (var i = 0; i < 5; i++)
            SignatureSpreadShadowCard(
              ritualCardId: _ritualByCanon[ids[i]]!,
              isReversed: false,
              positionIndex: i,
            ),
        ],
      ),
    );
    expect(shadow.ok, isTrue);
    expect(
      shadow.phase3EvidenceStatus,
      SignaturePhase3EvidenceStatus.builtSignature,
    );
    expect(shadow.classicalRequest!.spread.spreadId, 'signature.crossroads');
  });
}
