/// Portrait result — staged reveal, reading, share, quiet close.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/app_motion.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_soft_reveal.dart';
import '../../../../core/theme/app_spacing.dart';
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
    required this.parts,
    required this.onRedraw,
    this.name = '',
    this.savedId,
  });

  final List<int> imageBytes;
  final SoulMateReadingParts parts;
  final VoidCallback onRedraw;
  final String name;
  final String? savedId;

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
        OraclySoftReveal(
          delay: AppMotionDuration.fast,
          duration: AppMotionDuration.medium,
          child: SoulMateInterpretationBlock(parts: parts),
        ),
        SizedBox(height: AppSpacing.md),
        OraclySoftReveal(
          delay: AppMotionDuration.medium,
          child: SoulMateShareAction(
            enabled: canShare,
            onLocked: () => PremiumAccess.prompt(context),
            discovery: DiscoveryShareBuilder.soulMate(
              portrait: imageBytes,
              interpretation: parts.joined,
              name: name,
            ),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        OraclySoftReveal(
          delay: AppMotionDuration.normal,
          child: SoulMateResultEpilogue(
            parts: parts,
            name: name,
            savedId: savedId,
            onRedraw: onRedraw,
          ),
        ),
      ],
    );
  }
}
