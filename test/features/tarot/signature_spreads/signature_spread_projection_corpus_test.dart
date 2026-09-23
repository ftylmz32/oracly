/// Phase 5B — frozen projection corpus lock.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/tarot/narrative/evidence/narrative_question_grounding.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_catalog.dart';
import 'package:oracly_new/features/tarot/signature_spreads/signature_spread_projector.dart';

import 'signature_projection_test_support.dart';

void main() {
  test('frozen signature projection corpus v1', () {
    final raw = File(
      'test/fixtures/tarot_signature_spread_projection_v1.json',
    ).readAsStringSync();
    final root = jsonDecode(raw) as Map<String, dynamic>;
    final scenarios = root['scenarios'] as List<dynamic>;
    expect(scenarios, hasLength(4));

    for (var i = 0; i < 4; i++) {
      final expected = Map<String, dynamic>.from(scenarios[i] as Map);
      final actual = serializeProjection(
        SignatureSpreadProjector.project(SignatureSpreadCatalog.launch[i]),
      );
      expect(actual['spreadId'], expected['spreadId']);
      expect(actual['runtimeEnumName'], expected['runtimeEnumName']);
      expect(actual['projectedSpreadId'], expected['projectedSpreadId']);
      expect(actual['legacyTypeName'], expected['legacyTypeName']);
      expect(actual['cardCount'], expected['cardCount']);
      expect(actual['positionKeys'], expected['positionKeys']);
      expect(actual['indices'], expected['indices']);
      expect(actual['roles'], expected['roles']);
      expect(actual['temporals'], expected['temporals']);
      expect(actual['interpretationOrder'], expected['interpretationOrder']);
      expect(
        actual['signatureGeometryHook'],
        expected['signatureGeometryHook'],
      );
      expect(actual['phase3Geometry'], expected['phase3Geometry']);
      expect(actual['lengthBand'], expected['lengthBand']);
      expect(actual['edges'], expected['edges']);
      expect(
        actual['projectedRelationRowCount'],
        expected['projectedRelationRowCount'],
      );
      expect(actual['offeredInLivePicker'], expected['offeredInLivePicker']);
      expect(actual['primaryQuestionKind'], expected['primaryQuestionKind']);
      final expKinds = List<String>.from(
        expected['supportedQuestionKinds'] as List,
      )..sort();
      expect(actual['supportedQuestionKinds'], expKinds);
      if (expected['relationshipUnsupported'] == true) {
        expect(
          SignatureSpreadCatalog.launch[i].supportedQuestionKinds.contains(
            QuestionKind.relationship,
          ),
          isFalse,
        );
      }
    }
  });
}
