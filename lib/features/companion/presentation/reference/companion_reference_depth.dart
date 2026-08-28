/// Compact KISA / DENGELİ / DERİN — length only, never a personality row.
library;

import 'package:flutter/material.dart';

import '../../copy/companion_copy.dart';
import '../../../../core/personality/or_response_depth.dart';
import 'companion_reference_output_chip.dart';

class CompanionReferenceDepth extends StatelessWidget {
  const CompanionReferenceDepth({
    super.key,
    required this.depth,
    required this.onChanged,
  });

  final OrResponseDepth depth;
  final ValueChanged<OrResponseDepth> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final value in OrResponseDepth.preferenceValues)
          CompanionOutputChip(
            selected: depth == value,
            label: CompanionCopy.depthLabel(value),
            semantics: CompanionCopy.depthLabel(value),
            onTap: () => onChanged(value),
          ),
      ],
    );
  }
}
