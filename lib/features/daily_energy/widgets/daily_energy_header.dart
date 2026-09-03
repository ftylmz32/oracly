/// OR-050 — Daily Energy Details screen header.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_icons.dart';
import '../../../core/design_system/app_layout.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/design_system/oracly_header_action.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/theme/app_spacing.dart';

class DailyEnergyDetailsHeader extends StatelessWidget {
  const DailyEnergyDetailsHeader({
    super.key,
    required this.moonPhaseLabel,
    required this.dateLabel,
  });

  final String moonPhaseLabel;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: Row(
        children: [
          OraclyHeaderAction(
            icon: AppIcons.back,
            label: OraclyL10n.t(L10nKeys.back),
            onTap: () => Navigator.of(context).maybePop(),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  OraclyL10n.t('energy.details.title').toUpperCase(),
                  textAlign: TextAlign.center,
                  style: OraclyChrome.engravedTitle(size: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  '$moonPhaseLabel · $dateLabel',
                  textAlign: TextAlign.center,
                  style: OraclyChrome.bodySecondary(size: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          SizedBox(
            width: AppLayout.headerActionSize,
            height: AppLayout.headerActionSize,
          ),
        ],
      ),
    );
  }
}
