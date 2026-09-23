/// Phase 5B — pure projection validation (typed violations).
library;

import '../narrative/evidence/narrative_spread_semantics.dart';
import 'signature_spread_definition.dart';
import 'signature_spread_edge.dart';
import 'signature_spread_projection_crossroads_checks.dart';
import 'signature_spread_semantic_projection.dart';
import 'signature_spread_validation.dart';

enum SignatureProjectionViolation {
  sourceInvalid,
  spreadIdMismatch,
  cardCountMismatch,
  positionCountMismatch,
  positionIndexMismatch,
  positionKeyMismatch,
  positionRoleMismatch,
  interpretationOrderMismatch,
  unknownEdgeEndpoint,
  selfEdge,
  duplicateEdgePair,
  emptyEdgeEndpoint,
  crossroadsEdgeCount,
  crossroadsRelationRowCount,
  crossroadsLegacyType,
  crossroadsGeometry,
  crossroadsLength,
  wrongTemporalOrientation,
}

class SignatureProjectionValidationResult {
  const SignatureProjectionValidationResult(this.violations);
  final List<SignatureProjectionViolation> violations;
  bool get isValid => violations.isEmpty;
}

abstract final class SignatureProjectionValidation {
  SignatureProjectionValidation._();

  static SignatureProjectionValidationResult validate(
    SignatureSpreadSemanticProjection projection,
  ) {
    final out = <SignatureProjectionViolation>[];
    final source = projection.source;
    final projected = projection.projected;
    final edges = projection.edges;

    if (!SignatureSpreadValidation.validateDefinition(source).isValid) {
      out.add(SignatureProjectionViolation.sourceInvalid);
    }
    if (source.spreadId != projected.spreadId) {
      out.add(SignatureProjectionViolation.spreadIdMismatch);
    }
    if (source.cardCount != projected.cardCount) {
      out.add(SignatureProjectionViolation.cardCountMismatch);
    }
    if (source.positions.length != projected.positions.length) {
      out.add(SignatureProjectionViolation.positionCountMismatch);
    }
    _checkPositions(source, projected, out);
    if (!_intEq(source.interpretationOrder, projected.interpretationOrder)) {
      out.add(SignatureProjectionViolation.interpretationOrderMismatch);
    }
    _checkEdges(source, edges, out);
    if (source.spreadId == 'signature.crossroads') {
      SignatureProjectionCrossroadsChecks.apply(
        projected,
        edges,
        projection,
        out,
      );
    }
    return SignatureProjectionValidationResult(
      List<SignatureProjectionViolation>.unmodifiable(out),
    );
  }

  static void _checkPositions(
    SignatureSpreadDefinition source,
    SpreadSemanticDefinition projected,
    List<SignatureProjectionViolation> out,
  ) {
    final n = source.positions.length < projected.positions.length
        ? source.positions.length
        : projected.positions.length;
    for (var i = 0; i < n; i++) {
      final s = source.positions[i];
      final p = projected.positions[i];
      if (s.index != p.index) {
        out.add(SignatureProjectionViolation.positionIndexMismatch);
      }
      if (s.positionKey != p.positionKey) {
        out.add(SignatureProjectionViolation.positionKeyMismatch);
      }
      if (s.role != p.role) {
        out.add(SignatureProjectionViolation.positionRoleMismatch);
      }
    }
  }

  static void _checkEdges(
    SignatureSpreadDefinition source,
    List<SignatureSpreadEdge> edges,
    List<SignatureProjectionViolation> out,
  ) {
    final keys = {for (final p in source.positions) p.positionKey};
    final pairs = <String>{};
    for (final e in edges) {
      if (e.fromPositionKey.trim().isEmpty || e.toPositionKey.trim().isEmpty) {
        out.add(SignatureProjectionViolation.emptyEdgeEndpoint);
        continue;
      }
      if (e.fromPositionKey == e.toPositionKey) {
        out.add(SignatureProjectionViolation.selfEdge);
      }
      if (!keys.contains(e.fromPositionKey) ||
          !keys.contains(e.toPositionKey)) {
        out.add(SignatureProjectionViolation.unknownEdgeEndpoint);
      }
      final a = e.fromPositionKey;
      final b = e.toPositionKey;
      final canon = a.compareTo(b) <= 0 ? '$a|$b' : '$b|$a';
      if (!pairs.add(canon)) {
        out.add(SignatureProjectionViolation.duplicateEdgePair);
      }
    }
  }

  static bool _intEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
