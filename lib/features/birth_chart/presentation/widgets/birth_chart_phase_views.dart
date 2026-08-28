/// Loading, error, and recovery surfaces for birth chart.
library;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/app_layout.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../shared/widgets/chamber_waiting_orb.dart';
import '../../../../shared/widgets/oracly_button.dart';
import '../../../../shared/widgets/oracly_empty_state.dart';
import '../../../../shared/widgets/oracly_error_state.dart';
import '../../copy/birth_chart_copy.dart';

class BirthChartLoadingView extends StatelessWidget {
  const BirthChartLoadingView({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenHorizontal,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ChamberWaitingOrb(),
            SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: ReadingTypography.bodyCore(),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class BirthChartErrorView extends StatelessWidget {
  const BirthChartErrorView({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return BirthChartRecoveryScroll(
      children: [
        OraclyErrorState(
          message: message,
          onRetry: onRetry,
          retryLabel: BirthChartCopy.retry,
          secondaryLabel: BirthChartCopy.startOver,
          onSecondary: onBack,
        ),
      ],
    );
  }
}

class BirthChartIncompleteView extends StatelessWidget {
  const BirthChartIncompleteView({
    super.key,
    required this.onRecover,
    required this.onStartOver,
    required this.onRegenerate,
    required this.onClearSaved,
    required this.canRegenerate,
  });

  final VoidCallback onRecover;
  final VoidCallback onStartOver;
  final VoidCallback onRegenerate;
  final VoidCallback onClearSaved;
  final bool canRegenerate;

  @override
  Widget build(BuildContext context) {
    return BirthChartRecoveryScroll(
      children: [
        OraclyEmptyState(
          imageAsset: AppAssets.homeAstrology,
          title: BirthChartCopy.incompleteJourneyTitle,
          message: BirthChartCopy.incompleteJourneyMessage,
          ctaLabel: BirthChartCopy.recoverJourney,
          onCta: onRecover,
        ),
        SizedBox(height: AppSpacing.lg),
        if (canRegenerate) ...[
          OraclyButton(
            text: BirthChartCopy.generateChart,
            isExpanded: true,
            onPressed: onRegenerate,
          ),
          SizedBox(height: AppSpacing.sm),
        ],
        OraclyButton(
          text: BirthChartCopy.startOver,
          type: OraclyButtonType.ghost,
          isExpanded: true,
          onPressed: onStartOver,
        ),
        SizedBox(height: AppSpacing.sm),
        OraclyButton(
          text: BirthChartCopy.clearSavedChart,
          type: OraclyButtonType.ghost,
          isExpanded: true,
          onPressed: onClearSaved,
        ),
      ],
    );
  }
}

class BirthChartRecoveryScroll extends StatelessWidget {
  const BirthChartRecoveryScroll({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            0,
            AppSpacing.lg,
            0,
            AppLayout.scrollBottomInset(context),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        );
      },
    );
  }
}
