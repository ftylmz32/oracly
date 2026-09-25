/// One-line evidence-scope disclosure on the result surface.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../copy/birth_chart_copy.dart';
import '../../evidence/birth_evidence.dart';
import '../../evidence/birth_evidence_classifier.dart';
import '../../evidence/birth_evidence_completeness.dart';
import '../../models/birth_profile.dart';
import '../../models/chart_fidelity.dart';

class BirthChartScopeNote extends StatelessWidget {
  const BirthChartScopeNote({
    super.key,
    required this.profile,
    this.fidelity,
  });

  final BirthProfile profile;
  final ChartCalculationFidelity? fidelity;

  @override
  Widget build(BuildContext context) {
    final text = _copy();
    if (text == null) return const SizedBox.shrink();
    return Text(text, style: OraclyChrome.bodySecondary(size: 12));
  }

  String? _copy() {
    if (fidelity == ChartCalculationFidelity.fullNatalEphemeris) {
      return BirthChartCopy.scopeFullNatal;
    }
    if (fidelity == ChartCalculationFidelity.reducedNatal) {
      return BirthChartCopy.scopeReduced;
    }
    final completeness = BirthEvidenceClassifier.classify(
      BirthEvidence.fromProfile(profile),
    );
    return switch (completeness) {
      BirthEvidenceCompleteness.full => BirthChartCopy.scopeFullNatal,
      BirthEvidenceCompleteness.missingDate => null,
      _ => BirthChartCopy.scopeReduced,
    };
  }
}
