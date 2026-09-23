/// Phase 5A — pure signature spread validation (no l10n / runtime IO).
library;

import 'signature_spread_definition.dart';

enum SignatureSpreadViolation {
  emptySpreadId,
  invalidVersion,
  emptyRuntimeEnumName,
  invalidCardCount,
  positionCountMismatch,
  duplicatePositionIndex,
  nonContiguousPositionIndex,
  emptyPositionKey,
  duplicatePositionKey,
  badInterpretationOrder,
  emptySupportedQuestionKinds,
  primaryKindUnsupported,
  invalidOutcomeSlot,
  invalidAdviceSlot,
  sameSpreadRecurrenceAuthViolation,
  duplicateCatalogSpreadId,
  duplicateCatalogRuntimeName,
  invalidCatalogOrder,
}

class SignatureSpreadValidationResult {
  const SignatureSpreadValidationResult(this.violations);

  final List<SignatureSpreadViolation> violations;

  bool get isValid => violations.isEmpty;
}

abstract final class SignatureSpreadValidation {
  SignatureSpreadValidation._();

  static SignatureSpreadValidationResult validateDefinition(
    SignatureSpreadDefinition d,
  ) {
    final out = <SignatureSpreadViolation>[];
    if (d.spreadId.trim().isEmpty) {
      out.add(SignatureSpreadViolation.emptySpreadId);
    }
    if (d.version < 1) out.add(SignatureSpreadViolation.invalidVersion);
    if (d.runtimeEnumName.trim().isEmpty) {
      out.add(SignatureSpreadViolation.emptyRuntimeEnumName);
    }
    if (d.cardCount <= 0) {
      out.add(SignatureSpreadViolation.invalidCardCount);
    }
    if (d.positions.length != d.cardCount) {
      out.add(SignatureSpreadViolation.positionCountMismatch);
    }
    _checkPositions(d, out);
    _checkOrder(d, out);
    if (d.supportedQuestionKinds.isEmpty) {
      out.add(SignatureSpreadViolation.emptySupportedQuestionKinds);
    } else if (!d.supportedQuestionKinds.contains(d.primaryQuestionKind)) {
      out.add(SignatureSpreadViolation.primaryKindUnsupported);
    }
    final keys = {for (final p in d.positions) p.positionKey};
    if (d.outcomeSlotKey != null && !keys.contains(d.outcomeSlotKey)) {
      out.add(SignatureSpreadViolation.invalidOutcomeSlot);
    }
    if (d.adviceSlotKey != null && !keys.contains(d.adviceSlotKey)) {
      out.add(SignatureSpreadViolation.invalidAdviceSlot);
    }
    if (!d.forbidSameSpreadAloneAuth) {
      out.add(SignatureSpreadViolation.sameSpreadRecurrenceAuthViolation);
    }
    return SignatureSpreadValidationResult(
      List<SignatureSpreadViolation>.unmodifiable(out),
    );
  }

  static SignatureSpreadValidationResult validateCatalog(
    List<SignatureSpreadDefinition> catalog, {
    required List<String> expectedSpreadIdsInOrder,
  }) {
    final out = <SignatureSpreadViolation>[];
    final ids = <String>{};
    final runtimes = <String>{};
    for (final d in catalog) {
      out.addAll(validateDefinition(d).violations);
      if (!ids.add(d.spreadId)) {
        out.add(SignatureSpreadViolation.duplicateCatalogSpreadId);
      }
      if (!runtimes.add(d.runtimeEnumName)) {
        out.add(SignatureSpreadViolation.duplicateCatalogRuntimeName);
      }
    }
    final actual = [for (final d in catalog) d.spreadId];
    if (!_stringListEq(actual, expectedSpreadIdsInOrder)) {
      out.add(SignatureSpreadViolation.invalidCatalogOrder);
    }
    return SignatureSpreadValidationResult(
      List<SignatureSpreadViolation>.unmodifiable(out),
    );
  }

  static void _checkPositions(
    SignatureSpreadDefinition d,
    List<SignatureSpreadViolation> out,
  ) {
    final seenIdx = <int>{};
    final seenKeys = <String>{};
    for (final p in d.positions) {
      if (!seenIdx.add(p.index)) {
        out.add(SignatureSpreadViolation.duplicatePositionIndex);
      }
      final key = p.positionKey.trim();
      if (key.isEmpty) {
        out.add(SignatureSpreadViolation.emptyPositionKey);
      } else if (!seenKeys.add(key)) {
        out.add(SignatureSpreadViolation.duplicatePositionKey);
      }
    }
    if (d.cardCount > 0 && d.positions.length == d.cardCount) {
      final expected = [for (var i = 0; i < d.cardCount; i++) i];
      final actual = [for (final p in d.positions) p.index]..sort();
      if (!_intListEq(actual, expected)) {
        out.add(SignatureSpreadViolation.nonContiguousPositionIndex);
      }
    }
  }

  static void _checkOrder(
    SignatureSpreadDefinition d,
    List<SignatureSpreadViolation> out,
  ) {
    if (d.interpretationOrder.length != d.cardCount) {
      out.add(SignatureSpreadViolation.badInterpretationOrder);
      return;
    }
    final seen = <int>{};
    for (final i in d.interpretationOrder) {
      if (i < 0 || i >= d.cardCount || !seen.add(i)) {
        out.add(SignatureSpreadViolation.badInterpretationOrder);
        return;
      }
    }
  }

  static bool _intListEq(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static bool _stringListEq(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
