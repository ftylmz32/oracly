/// Phase 5A — deterministic immutable launch catalog.
library;

import 'signature_spread_crossroads.dart';
import 'signature_spread_deep_field.dart';
import 'signature_spread_definition.dart';
import 'signature_spread_quick_insight.dart';
import 'signature_spread_timeline.dart';
import 'signature_spread_validation.dart';

/// Canonical launch order (locked).
const kSignatureLaunchSpreadIds = <String>[
  'classical.single',
  'classical.threeCard',
  'classical.fiveCard',
  'signature.crossroads',
];

abstract final class SignatureSpreadCatalog {
  SignatureSpreadCatalog._();

  static final List<SignatureSpreadDefinition> _launch =
      List<SignatureSpreadDefinition>.unmodifiable([
        kSignatureQuickInsight,
        kSignatureTimeline,
        kSignatureDeepField,
        kSignatureCrossroads,
      ]);

  /// Immutable launch catalog in locked order.
  static List<SignatureSpreadDefinition> get launch => _launch;

  static SignatureSpreadValidationResult validateLaunch() {
    return SignatureSpreadValidation.validateCatalog(
      launch,
      expectedSpreadIdsInOrder: kSignatureLaunchSpreadIds,
    );
  }

  static SignatureSpreadDefinition? bySpreadId(String spreadId) {
    for (final d in _launch) {
      if (d.spreadId == spreadId) return d;
    }
    return null;
  }
}
