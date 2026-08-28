/// Saved coffee readings — reopen the same result.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/design_system/app_layout.dart';
import '../../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../../core/design_system/oracly_glass_card.dart';
import '../../../../shared/widgets/oracly_empty_state.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../copy/coffee_copy.dart';
import '../../models/coffee_reading.dart';
import '../../providers/coffee_providers.dart';
import 'coffee_reference_app_bar.dart';
import 'coffee_reference_atmosphere.dart';
import 'coffee_reference_tokens.dart';

class CoffeeHistoryScreen extends ConsumerWidget {
  const CoffeeHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(coffeeReadingControllerProvider);
    final items = controller.history;

    return OraclyScaffold(
      safeArea: false,
      backgroundOverlay: const CoffeeReferenceAtmosphere(
        child: SizedBox.shrink(),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            CoffeeReferenceTokens.screenHorizontal,
            CoffeeReferenceTokens.screenTop,
            CoffeeReferenceTokens.screenHorizontal,
            AppLayout.scrollBottomInset(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CoffeeReferenceAppBar(onBack: () => Navigator.maybePop(context)),
              SizedBox(height: CoffeeReferenceTokens.gap),
              Text(
                CoffeeCopy.historyTitle,
                style: ReadingTypography.sectionTitle(
                  color: OraclyChrome.goldLight,
                ),
              ),
              SizedBox(height: AppSpacing.sm),
              Expanded(
                child: items.isEmpty
                    ? OraclyEmptyState(
                        kind: OraclyLoadingKind.coffee,
                        imageAsset: AppAssets.coffeeRitualHero,
                        warm: true,
                        message: CoffeeCopy.emptyHistory,
                        ctaLabel: CoffeeCopy.photoCta,
                        onCta: () => Navigator.maybePop(context),
                      )
                    : ListView.separated(
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          return _HistoryRow(
                            reading: items[index],
                            onTap: () {
                              final reading = items[index];
                              controller.openSaved(reading);
                              Navigator.of(context).pop();
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.reading, required this.onTap});

  final CoffeeReading reading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final date =
        '${reading.createdAt.day}.${reading.createdAt.month}.${reading.createdAt.year}';
    return OraclyGlassCard(
      onTap: onTap,
      premium: true,
      glowStrength: 1.08,
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            date,
            style: ReadingTypography.micro(color: OraclyChrome.goldLight),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            reading.overall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ReadingTypography.bodySmall(
              color: CoffeeReferenceTokens.cream.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }
}
