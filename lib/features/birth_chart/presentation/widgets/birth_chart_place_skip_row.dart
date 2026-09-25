/// Quiet place-skip affordance under the birth place field.
library;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/oracly_text_action.dart';
import '../../copy/birth_chart_copy.dart';

class BirthChartPlaceSkipRow extends StatelessWidget {
  const BirthChartPlaceSkipRow({
    super.key,
    required this.placeSkipped,
    this.onSkipPlace,
  });

  final bool placeSkipped;
  final VoidCallback? onSkipPlace;

  @override
  Widget build(BuildContext context) {
    if (onSkipPlace == null || placeSkipped) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: EdgeInsets.only(top: AppSpacing.s4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: OraclyTextAction(
          label: BirthChartCopy.placeUnknownAction,
          onPressed: onSkipPlace,
        ),
      ),
    );
  }
}
