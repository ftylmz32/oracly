/// Phase 5A — launch catalog positive contracts.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_spread_semantics.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_catalog.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_enums.dart';

void main() {
  group('SignatureSpreadCatalog launch', () {
    test('count, order, uniqueness, immutability, determinism', () {
      final a = SignatureSpreadCatalog.launch;
      final b = SignatureSpreadCatalog.launch;
      expect(a, hasLength(4));
      expect(identical(a, b), isTrue);
      expect(
        a.map((d) => d.spreadId).toList(),
        kSignatureLaunchSpreadIds,
      );
      expect(a.map((d) => d.spreadId).toSet(), hasLength(4));
      expect(a.map((d) => d.runtimeEnumName).toSet(), hasLength(4));
      expect(
        () => a.add(a.first),
        throwsUnsupportedError,
      );
      expect(SignatureSpreadCatalog.validateLaunch().isValid, isTrue);
    });

    test('card counts and geometry', () {
      final c = SignatureSpreadCatalog.launch;
      expect(c.map((d) => d.cardCount).toList(), [1, 3, 5, 5]);
      expect(c[0].signatureGeometryHook, SignatureGeometryHook.single);
      expect(c[1].signatureGeometryHook, SignatureGeometryHook.threeLinear);
      expect(c[2].signatureGeometryHook, SignatureGeometryHook.fiveLinear);
      expect(c[3].signatureGeometryHook, SignatureGeometryHook.fiveDecision);
    });

    test('Quick Insight / Timeline / Deep Field locks', () {
      final qi = SignatureSpreadCatalog.launch[0];
      expect(qi.spreadId, 'classical.single');
      expect(qi.positions.single.positionKey, 'sign');
      expect(qi.positions.single.role, PositionRole.signal);
      expect(qi.supportedQuestionKinds, {
        QuestionKind.open,
        QuestionKind.guidance,
      });
      expect(qi.primaryQuestionKind, QuestionKind.open);

      final tl = SignatureSpreadCatalog.launch[1];
      expect(
        tl.positions.map((p) => p.positionKey).toList(),
        ['past', 'present', 'future'],
      );
      expect(
        tl.positions.map((p) => p.role).toList(),
        [PositionRole.root, PositionRole.state, PositionRole.direction],
      );

      final df = SignatureSpreadCatalog.launch[2];
      expect(
        df.positions.map((p) => p.positionKey).toList(),
        [
          'situation',
          'hidden_influence',
          'challenge',
          'strength',
          'direction',
        ],
      );
      expect(df.adviceSlotKey, 'strength');
      expect(df.outcomeSlotKey, 'direction');
    });

    test('Crossroads locks — unreachable, no relationship', () {
      final cr = SignatureSpreadCatalog.launch[3];
      expect(cr.spreadId, 'signature.crossroads');
      expect(cr.runtimeEnumName, 'crossroads');
      expect(cr.cardCount, 5);
      expect(cr.offeredInLivePicker, isFalse);
      expect(cr.primaryQuestionKind, QuestionKind.decision);
      expect(cr.supportedQuestionKinds, {
        QuestionKind.decision,
        QuestionKind.open,
        QuestionKind.guidance,
      });
      expect(cr.supportedQuestionKinds.contains(QuestionKind.relationship), isFalse);
      expect(
        cr.positions.map((p) => '${p.positionKey}:${p.role.name}').toList(),
        [
          'option_a:direction',
          'option_b:direction',
          'tension:challenge',
          'counsel:support',
          'direction:direction',
        ],
      );
      expect(cr.adviceSlotKey, 'counsel');
      expect(cr.outcomeSlotKey, 'direction');
      expect(cr.forbidSameSpreadAloneAuth, isTrue);
      expect(cr.allowHistoricalContextOverlap, isTrue);
      expect(
        cr.memoryInclusionPosture,
        SignatureMemoryInclusionPosture.normal,
      );
      expect(cr.signatureGeometryHook, SignatureGeometryHook.fiveDecision);
    });
  });
}
