/// SoulMate chamber entry — cinematic plate, never an illustrated stub.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/copy/premium_copy.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../features/premium/copy/soul_mate_copy.dart';
import '../../../features/premium/providers/premium_providers.dart';
import '../../../features/premium/providers/soul_mate_saved_provider.dart';
import '../../../features/premium/services/premium_access.dart';
import '../../../features/premium/services/soul_mate_dev_access.dart';
import '../../../features/premium/services/soul_mate_navigation.dart';
import '../../../shared/widgets/oracly_asset_image.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import 'profile_reference_card_shell.dart';
import 'profile_surface_weight.dart';

class ProfileSoulMateEntryRow extends ConsumerWidget {
  const ProfileSoulMateEntryRow({super.key});

  bool _canOpen(bool isPremium) =>
      isPremium || SoulMateDevAccess.allowsTestAccess;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumStatusProvider).isPremium;
    final locked = !_canOpen(isPremium);
    final portraitPath = ref.watch(soulMateSavedPortraitProvider).valueOrNull;
    final hasSaved = portraitPath != null && File(portraitPath).existsSync();

    return ProfileReferenceCardShell(
      weight: ProfileSurfaceWeight.story,
      glowStrength: 0.72,
      padding: EdgeInsets.zero,
      child: OraclyPressable(
        onTap: () {
          if (locked) {
            PremiumAccess.prompt(context);
            return;
          }
          SoulMateNavigation.open(context);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasSaved)
                    Image.file(
                      File(portraitPath),
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                    )
                  else
                    OraclyAssetImage(
                      assetPath: AppAssets.profileSoulMatePlaceholder,
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.high,
                      fallback: ColoredBox(
                        color: OraclyChrome.midnight.withValues(alpha: 0.85),
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          OraclyChrome.midnight.withValues(alpha: 0.78),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                SoulMateCopy.listTitle,
                                softWrap: true,
                                style: AppTextStyles.labelLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: OraclyChrome.goldLight.withValues(
                                    alpha: 0.94,
                                  ),
                                ),
                              ),
                            ),
                            if (locked) ...[
                              SizedBox(width: AppSpacing.s8),
                              Text(
                                PremiumCopy.exclusiveLabel,
                                style: ReadingTypography.sectionLabel(
                                  color: OraclyChrome.goldLight.withValues(
                                    alpha: 0.78,
                                  ),
                                  fontSize: 9,
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: AppSpacing.s4),
                        Text(
                          hasSaved
                              ? SoulMateCopy.listDescriptionSaved
                              : SoulMateCopy.listDescription,
                          softWrap: true,
                          style: ReadingTypography.bodyCore(
                            color: OraclyChrome.cream.withValues(alpha: 0.72),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    locked
                        ? Icons.lock_outline_rounded
                        : Icons.chevron_right_rounded,
                    size: locked ? 18 : 20,
                    color: OraclyChrome.gold.withValues(
                      alpha: locked ? 0.55 : 0.36,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
