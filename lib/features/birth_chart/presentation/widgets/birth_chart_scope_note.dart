/// One-line evidence-scope disclosure on the result surface.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../copy/birth_chart_copy.dart';
import '../../evidence/birth_evidence.dart';
import '../../evidence/birth_evidence_classifier.dart';
import '../../evidence/birth_evidence_completeness.dart';
import '../../models/birth_profile.dart';

class BirthChartScopeNote extends StatelessWidget {
  const BirthChartScopeNote({super.key, required this.profile});

  final BirthProfile profile;

  @override
  Widget build(BuildContext context) {
    final completeness = BirthEvidenceClassifier.classify(
      BirthEvidence.fromProfile(profile),
    );
    final text = switch (completeness) {
      BirthEvidenceCompleteness.full =>
        BirthChartCopy.scopeEvidenceFullCalcPending,
      BirthEvidenceCompleteness.missingDate => null,
      _ => BirthChartCopy.scopeReduced,
    };
    if (text == null) return const SizedBox.shrink();
    return Text(text, style: OraclyChrome.bodySecondary(size: 12));
  }
}
