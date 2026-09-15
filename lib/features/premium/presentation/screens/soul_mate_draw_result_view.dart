/// Portrait result — staged reveal, reading, share, quiet close.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_motion.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_soft_reveal.dart';
import '../../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/oracly_error_state.dart';
import '../../../../features/discovery_share/services/discovery_share_builder.dart';
import '../../copy/soul_mate_copy.dart';
import '../../data/soul_mate_interpretation_catalogue.dart';
import '../../providers/premium_providers.dart';
import '../../services/premium_access.dart';
import '../../services/soul_mate_dev_access.dart';
import 'soul_mate_interpretation_block.dart';
import 'soul_mate_portrait_reveal.dart';
import 'soul_mate_result_epilogue.dart';
import 'soul_mate_share_action.dart';

class SoulMateDrawResultView extends ConsumerWidget {
  const SoulMateDrawResultView({
    super.key,
    required this.imageBytes,
    required this.onRedraw,
    this.parts,
    this.name = '',
    this.savedId,
    this.interpretationBusy = false,
    this.interpretationFailed = false,
    this.onRetryInterpretation,
  });

  final List<int> imageBytes;
  final SoulMateReadingParts? parts;
  final VoidCallback onRedraw;
  final String name;
  final String? savedId;
  final bool interpretationBusy;
  final bool interpretationFailed;
  final VoidCallback? onRetryInterpretation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumStatusProvider).isPremium;
    final canShare =
        isPremium || SoulMateDevAccess.allowsTestAccess;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          SoulMateCopy.brandMark,
          textAlign: TextAlign.center,
          style: OraclyChrome.sectionLabel(size: 11),
        ),
        SizedBox(height: AppSpacing.sm),
        SoulMatePortraitReveal(imageBytes: imageBytes),
        SizedBox(height: AppSpacing.md),
        if (interpretationBusy)
          Text(
            SoulMateCopy.interpreting,
            textAlign: TextAlign.center,
            style: OraclyChrome.sectionLabel(size: 11),
          )
        else if (parts != null && parts!.authoritative)
          OraclySoftReveal(
            delay: AppMotionDuration.fast,
            duration: AppMotionDuration.medium,
            child: SoulMateInterpretationBlock(parts: parts!),
          )
        else if (interpretationFailed)
          OraclyErrorState(
            kind: OraclyLoadingKind.soulMate,
            compact: true,
            message: SoulMateCopy.interpretationFailed,
            onRetry: onRetryInterpretation,
            retryLabel: SoulMateCopy.retry,
          ),
        SizedBox(height: AppSpacing.md),
        OraclySoftReveal(
          delay: AppMotionDuration.medium,
          child: SoulMateShareAction(
            enabled: canShare,
            onLocked: () => PremiumAccess.prompt(context),
            discovery: DiscoveryShareBuilder.soulMate(
              portrait: imageBytes,
              interpretation: parts?.authoritative == true ? parts!.joined : '',
              name: name,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        OraclySoftReveal(
          delay: AppMotionDuration.normal,
          child: SoulMateResultEpilogue(
            parts: parts ??
                const SoulMateReadingParts(
                  energy: '',
                  attraction: '',
                  dynamics: '',
                  feeling: '',
                  yourSide: '',
                ),
            name: name,
            savedId: savedId,
            onRedraw: onRedraw,
          ),
        ),
      ],
    );
  }
}
