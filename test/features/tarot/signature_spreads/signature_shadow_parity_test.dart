/// Phase 5E — classical parity, privacy, Crossroads firewall, determinism.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_bridge.dart';
import 'package:oracly_new/features/tarot/deck/oracly_tarot_deck.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_classical_spread_catalog.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_builder.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_evidence_input.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_historical_models.dart';
import 'package:oracly_new/features/tarot/narrative/history/tarot_narrative_request_enricher.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_migration_seam.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_evaluator.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_input.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_result.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_shadow_status.dart';

final _ritualByCanon = <String, int>{
  for (var i = 0; i < 78; i++) OraclyTarotBridge.byRitualId(i)!.id: i,
};

List<SignatureSpreadShadowCard> _shadowCards(
  TarotSpreadType type,
  List<(String, bool)> drawn,
) {
  return [
    for (var i = 0; i < drawn.length; i++)
      SignatureSpreadShadowCard(
        ritualCardId: _ritualByCanon[drawn[i].$1]!,
        isReversed: drawn[i].$2,
        positionIndex: i,
      ),
  ];
}

NarrativeEvidenceInput _directInput(
  TarotSpreadType type,
  List<(String, bool)> drawn, {
  String lang = 'en',
  String? question,
}) {
  final def = ClassicalSpreadSemantics.byLegacyTypeName(type.name);
  return NarrativeEvidenceInput(
    sessionId: 'sess_parity',
    readingId: 'read_parity',
    languageCode: lang,
    questionRaw: question,
    spreadType: type,
    cards: [
      for (var i = 0; i < drawn.length; i++)
        NarrativeEvidenceCardInput(
          canonicalCardId: drawn[i].$1,
          ritualCardId: _ritualByCanon[drawn[i].$1]!,
          isReversed: drawn[i].$2,
          positionKey: def.positions[i].positionKey,
          positionIndex: def.positions[i].index,
        ),
    ],
  );
}

void main() {
  final ids = OraclyTarotDeck.expectedIds;
  final now = DateTime.utc(2026, 9, 23, 12);

  group('classical Phase 3 parity', () {
    for (final type in [
      TarotSpreadType.single,
      TarotSpreadType.threeCard,
      TarotSpreadType.fiveCard,
    ]) {
      test('${type.name} shadow == direct builder', () {
        final drawn = [
          for (final id in ids.take(type.cardCount)) (id, false),
        ];
        final direct = NarrativeEvidenceBuilder.build(
          _directInput(type, drawn, question: 'Need guidance for my next step'),
        );
        final shadow = SignatureSpreadShadowEvaluator.evaluate(
          input: SignatureSpreadShadowInput(
            sessionId: 'sess_parity',
            readingId: 'read_parity',
            languageCode: 'en',
            spreadType: type,
            questionRaw: 'Need guidance for my next step',
            cards: _shadowCards(type, drawn),
          ),
        );
        expect(shadow.ok, isTrue);
        expect(
          shadow.phase3EvidenceStatus,
          SignaturePhase3EvidenceStatus.builtClassical,
        );
        final req = shadow.classicalRequest!;
        expect(req.spread.spreadId, direct.spread.spreadId);
        expect(req.question.kind, direct.question.kind);
        expect(req.languageCode, direct.languageCode);
        expect(
          [for (final c in req.cards) c.canonicalCardId],
          [for (final c in direct.cards) c.canonicalCardId],
        );
        expect(
          [for (final c in req.cards) c.positionKey],
          [for (final c in direct.cards) c.positionKey],
        );
        expect(
          [for (final r in req.relationships) r.evidenceId]..sort(),
          [for (final r in direct.relationships) r.evidenceId]..sort(),
        );
        expect(req.bounds.maxRelationships, direct.bounds.maxRelationships);
        expect(req.narrativeTarotVersion, direct.narrativeTarotVersion);
      });
    }
  });

  test('privacy short-circuit parity via shadow', () {
    final drawn = [(ids.first, false)];
    final shadowBase = SignatureSpreadShadowEvaluator.evaluate(
      input: SignatureSpreadShadowInput(
        sessionId: 's',
        readingId: 'r',
        languageCode: 'en',
        spreadType: TarotSpreadType.single,
        cards: _shadowCards(TarotSpreadType.single, drawn),
      ),
    );
    final history = TarotHistoricalSnapshot(
      tarotReadings: [
        TarotHistoricalReadingRecord(
          readingId: 'prior',
          occurredAt: now.subtract(const Duration(days: 2)),
          spreadId: 'classical.single',
          cards: [
            TarotHistoricalCardOccurrence(
              canonicalCardId: ids.first,
              isReversed: false,
            ),
          ],
        ),
      ],
    );
    final shadow = SignatureSpreadShadowEvaluator.evaluate(
      input: SignatureSpreadShadowInput(
        sessionId: 's',
        readingId: 'r',
        languageCode: 'en',
        spreadType: TarotSpreadType.single,
        cards: _shadowCards(TarotSpreadType.single, drawn),
      ),
      history: history,
      privacyBlocked: true,
      now: now,
    );
    final direct = TarotNarrativeRequestEnricher.enrich(
      base: shadowBase.classicalRequest!,
      history: history,
      currentOwnerId: null,
      privacyBlocked: true,
      now: now,
    );
    expect(shadow.phase4HistoryStatus, SignaturePhase4HistoryStatus.privacyBlocked);
    expect(shadow.enrichedRequest!.memory.omitReason, 'privacy');
    expect(shadow.enrichedRequest!.memory.included, isFalse);
    expect(shadow.enrichedRequest!.recurringCards, isEmpty);
    expect(shadow.enrichedRequest!.recurringThemes, isEmpty);
    expect(direct.memory.omitReason, 'privacy');
  });

  test('Crossroads never builds Phase3 or enriches Phase4', () {
    final five = ids.take(5).map((id) => (id, false)).toList();
    final shadow = SignatureSpreadShadowEvaluator.evaluate(
      input: SignatureSpreadShadowInput(
        sessionId: 's',
        readingId: 'r',
        languageCode: 'en',
        spreadType: TarotSpreadType.crossroads,
        questionRaw: 'Should I accept this offer?',
        cards: _shadowCards(TarotSpreadType.crossroads, five),
      ),
      history: TarotHistoricalSnapshot(tarotReadings: const []),
      now: now,
    );
    expect(shadow.ok, isTrue);
    expect(
      shadow.phase3EvidenceStatus,
      SignaturePhase3EvidenceStatus.blockedUnsupportedSignatureSpread,
    );
    expect(
      shadow.phase4HistoryStatus,
      SignaturePhase4HistoryStatus.blockedUnsupportedSignatureSpread,
    );
    expect(shadow.classicalRequest, isNull);
    expect(shadow.enrichedRequest, isNull);
    expect(shadow.structuralEdgeGraphAvailable, isTrue);
    expect(shadow.phase3EdgeAwareScoringAvailable, isFalse);
    expect(shadow.projection!.edges, hasLength(4));
    expect(shadow.projection!.projectedRelationRowCount, 7);
    expect(shadow.definition!.spreadId, isNot('classical.fiveCard'));
  });

  test('migration seam launch matrix', () {
    final matrix = SignatureSpreadMigrationSeam.launchMatrix();
    expect(matrix, hasLength(4));
    expect(matrix[0].spreadId, 'classical.single');
    expect(matrix[0].phase3EvidenceSupported, isTrue);
    expect(matrix[0].pickerOffered, isTrue);
    expect(matrix[0].liveNarrativeV2Supported, isFalse);
    expect(matrix[3].spreadId, 'signature.crossroads');
    expect(matrix[3].phase3EvidenceSupported, isFalse);
    expect(matrix[3].phase4HistorySupported, isFalse);
    expect(matrix[3].phase3SignatureEdgesConsumed, isFalse);
    expect(matrix[3].pickerOffered, isFalse);
  });

  test('determinism + input permutation', () {
    final five = [
      (ids[0], false),
      (ids[1], true),
      (ids[2], false),
      (ids[3], true),
      (ids[4], false),
    ];
    SignatureSpreadShadowResult run(List<SignatureSpreadShadowCard> cards) {
      return SignatureSpreadShadowEvaluator.evaluate(
        input: SignatureSpreadShadowInput(
          sessionId: 's',
          readingId: 'r',
          languageCode: 'ENGLISH',
          spreadType: TarotSpreadType.fiveCard,
          cards: cards,
        ),
      );
    }

    final ordered = _shadowCards(TarotSpreadType.fiveCard, five);
    final permuted = [...ordered.reversed];
    final a = run(ordered);
    final b = run(ordered);
    final c = run(permuted);
    expect(a.structuralFingerprint, b.structuralFingerprint);
    expect(a.structuralFingerprint, c.structuralFingerprint);
    expect(
      [for (final x in a.cards!) x.canonicalCardId],
      [for (final x in c.cards!) x.canonicalCardId],
    );
  });
}
