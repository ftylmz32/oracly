/// Premium empty state — feature atmosphere plate, one sentence, clear CTA.
library;

import 'package:flutter/material.dart';

import '../../core/design_system/async_state/oracly_async_atmosphere.dart';
import '../../core/design_system/async_state/oracly_async_emblem.dart';
import '../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../core/design_system/micro_details/micro_details.dart';
import '../../core/design_system/oracly_chrome.dart';
import '../../core/design_system/premium_button.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/reading_typography.dart';

class OraclyEmptyState extends StatelessWidget {
  const OraclyEmptyState({
    super.key,
    required this.message,
    this.title,
    this.kind = OraclyLoadingKind.chamber,
    this.imageAsset,
    this.warm,
    @Deprecated('Prefer kind — cartoon icons are not used.')
    this.icon = Icons.nights_stay_rounded,
    this.ctaLabel,
    this.onCta,
  });

  final String message;
  final String? title;
  final OraclyLoadingKind kind;
  final String? imageAsset;
  final bool? warm;
  final IconData icon;
  final String? ctaLabel;
  final VoidCallback? onCta;

  @override
  Widget build(BuildContext context) {
    return MicroEmptyAmbience(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              OraclyAsyncEmblem(
                kind: kind,
                size: 112,
                assetPath: imageAsset ?? OraclyAsyncAtmosphere.plate(kind),
                warm: warm,
              ),
              SizedBox(height: AppSpacing.lg),
              if (title != null) ...[
                Text(
                  title!,
                  textAlign: TextAlign.center,
                  style: ReadingTypography.title(
                    color: OraclyChrome.goldLight.withValues(alpha: 0.92),
                  ),
                ),
                SizedBox(height: AppSpacing.md),
              ],
              Text(
                message,
                textAlign: TextAlign.center,
                style: ReadingTypography.body(
                  color: OraclyChrome.cream.withValues(alpha: 0.78),
                ),
              ),
              if (ctaLabel != null && onCta != null) ...[
                SizedBox(height: AppSpacing.xl),
                PremiumButton(
                  label: ctaLabel!,
                  onPressed: onCta,
                  variant: PremiumButtonVariant.primary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
