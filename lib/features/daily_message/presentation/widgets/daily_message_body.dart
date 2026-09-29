/// Settled Günün Mesajı column — card, actions, and one next step.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/insight_copy/widgets/insight_copy_link.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../discovery_share/services/discovery_share_builder.dart';
import '../../../discovery_share/widgets/discovery_share_action.dart';
import '../../../favorite_moments/presentation/widgets/save_favorite_moment_link.dart';
import '../../../favorite_moments/services/favorite_moment_factory.dart';
import '../../copy/daily_message_copy.dart';
import '../../models/daily_message.dart';
import '../../models/daily_return_action.dart';
import 'daily_message_card.dart';
import 'daily_return_cta.dart';

class DailyMessageBody extends StatelessWidget {
  const DailyMessageBody({
    super.key,
    required this.message,
    required this.showReentry,
    required this.reason,
    required this.recommendationLabel,
    required this.ctaAction,
  });

  final DailyMessage message;
  final bool showReentry;
  final String? reason;
  final String recommendationLabel;
  final DailyReturnAction ctaAction;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Align(
              alignment: const Alignment(0, -0.18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DailyMessageCard(message: message),
                    InsightCopyLink(text: message.text),
                    SaveFavoriteMomentLink(
                      draft: FavoriteMomentFactory.daily(message),
                    ),
                    DiscoveryShareAction(
                      discovery: DiscoveryShareBuilder.dailyInsight(
                        highlight: message.text,
                      ),
                    ),
                    if (showReentry) ...[
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        DailyMessageCopy.discoveryTitle,
                        textAlign: TextAlign.center,
                        style: ReadingTypography.sectionLabel(
                          color: OraclyChrome.goldLight.withValues(alpha: 0.9),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      if (reason != null) ...[
                        Text(
                          reason!,
                          textAlign: TextAlign.center,
                          style: ReadingTypography.body(
                            color: OraclyChrome.cream.withValues(alpha: 0.78),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s8),
                      ],
                      Text(
                        recommendationLabel,
                        textAlign: TextAlign.center,
                        style: ReadingTypography.bodyCore(
                          color: OraclyChrome.goldLight.withValues(alpha: 0.94),
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.s8),
                    DailyReturnCta(action: ctaAction, message: message),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
