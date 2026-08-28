/// Home Premium banner — crown left, copy center, gold CTA, art right.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/accessibility/oracly_a11y.dart';
import '../../../core/copy/premium_copy.dart';
import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/reading_typography.dart';
import '../../premium/providers/premium_providers.dart';
import 'home_reference_card_shell.dart';
import 'home_reference_premium_art.dart';
import 'home_reference_premium_copy.dart';
import 'home_reference_premium_cta.dart';
import 'home_reference_scope.dart';
import 'home_reference_tokens.dart';

class HomeReferencePremiumCard extends ConsumerWidget {
  const HomeReferencePremiumCard({super.key, this.onExploreTap});

  final VoidCallback? onExploreTap;

  void _handleTap(BuildContext context) {
    if (onExploreTap != null) {
      onExploreTap!();
      return;
    }
    OraclyNavigationService.openPremium(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(premiumStatusProvider);
    final copy = HomeReferencePremiumCopy.resolve(status);
    final layout = HomeReferenceScope.maybeOf(context);
    final pad =
        layout?.premiumPadding ?? const EdgeInsets.fromLTRB(12, 8, 10, 8);
    final crown = layout?.premiumCrownSize ?? 34;
    final cta =
        status.isPremium ? PremiumCopy.ctaActive : PremiumCopy.ctaJoin;

    return LayoutBuilder(
      builder: (context, constraints) {
        final slotH =
            constraints.maxHeight.isFinite ? constraints.maxHeight : null;
        return Semantics(
          button: true,
          label: '${copy.title}. ${copy.body}. $cta',
          child: HomeReferenceCardShell(
            height: slotH,
            premium: true,
            glowStrength: copy.glowStrength,
            borderRadius: HomeReferenceTokens.premiumRadius,
            padding: EdgeInsets.zero,
            onTap: () => _handleTap(context),
            child: ClipRRect(
              borderRadius: HomeReferenceTokens.premiumRadius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HomeReferencePremiumArt(crownSize: crown),
                  Padding(
                    padding: pad,
                    child: Row(
                      children: [
                        DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: OraclyChrome.gold.withValues(alpha: 0.28),
                                blurRadius: 12,
                                spreadRadius: 0.5,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.workspace_premium_rounded,
                            size: crown,
                            color: OraclyA11y.goldReadable(
                              OraclyChrome.goldLight,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s12),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 220),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    copy.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: ReadingTypography.sectionTitle(
                                      fontSize: 14,
                                    ).copyWith(
                                      color: OraclyA11y.goldReadable(
                                        OraclyChrome.goldLight,
                                      ),
                                      fontWeight: FontWeight.w700,
                                      height: 1.08,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    copy.body,
                                    maxLines: copy.maxBodyLines,
                                    overflow: TextOverflow.ellipsis,
                                    style: ReadingTypography.secondary(
                                      color: OraclyA11y.creamSecondary(
                                        OraclyChrome.cream,
                                      ),
                                    ).copyWith(fontSize: 11, height: 1.2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        HomeReferencePremiumCta(
                          label: cta,
                          onTap: () => _handleTap(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
