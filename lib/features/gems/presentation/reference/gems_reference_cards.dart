/// Compact cards for Mücevherler — history + daily entry + honesty.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/remote_config/remote_config_runtime.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../copy/gems_copy.dart';
import '../../models/gem_transaction.dart';
import '../../providers/gem_providers.dart';
import 'gems_history_empty.dart';
import 'gems_reference_tokens.dart';

class GemsInfoCard extends StatelessWidget {
  const GemsInfoCard({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return OraclyGlassCard(
      borderRadius: GemsReferenceTokens.cardRadius,
      padding: GemsReferenceTokens.cardPadding,
      premium: true,
      glowStrength: 1.04,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.labelMedium.copyWith(
              color: OraclyChrome.goldLight.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.84),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class GemsHistoryCard extends ConsumerWidget {
  const GemsHistoryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limit = RemoteConfigRuntime.snapshot.gemHistoryDisplayLimit;
    final items = ref.watch(gemWalletProvider).history.take(limit).toList();
    if (items.isEmpty) {
      return OraclyGlassCard(
        borderRadius: GemsReferenceTokens.cardRadius,
        padding: GemsReferenceTokens.cardPadding,
        premium: true,
        glowStrength: 1.04,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              GemsCopy.historyTitle,
              style: AppTextStyles.labelMedium.copyWith(
                color: OraclyChrome.goldLight.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const GemsHistoryEmpty(),
          ],
        ),
      );
    }
    return GemsInfoCard(
      title: GemsCopy.historyTitle,
      body: items.map((GemTransaction tx) => tx.displayLine).join('\n'),
    );
  }
}
