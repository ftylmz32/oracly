/// Home gems banner — live wallet balance, never a second wallet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/gems/copy/gems_copy.dart';
import '../../../features/gems/providers/gem_providers.dart';
import 'home_gems_strip_plate.dart';
import 'home_gems_strip_scrim.dart';
import 'home_reference_card_shell.dart';
import 'home_reference_scope.dart';
import 'home_reference_tokens.dart';

class HomeReferenceGemsBanner extends ConsumerWidget {
  const HomeReferenceGemsBanner({super.key, this.onTap});

  final VoidCallback? onTap;

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    OraclyNavigationService.openGems(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(gemWalletProvider).formatted;
    final layout = HomeReferenceScope.maybeOf(context);
    final pad =
        layout?.premiumPadding ?? const EdgeInsets.fromLTRB(14, 10, 10, 10);

    return LayoutBuilder(
      builder: (context, constraints) {
        final slotH =
            constraints.maxHeight.isFinite ? constraints.maxHeight : null;
        return Semantics(
          button: true,
          label: '${GemsCopy.screenTitle}. $balance. ${GemsCopy.balanceLabel}',
          child: HomeReferenceCardShell(
            height: slotH,
            premium: false,
            glowStrength: 0.62,
            borderRadius: HomeReferenceTokens.premiumRadius,
            padding: EdgeInsets.zero,
            onTap: () => _handleTap(context),
            child: ClipRRect(
              borderRadius: HomeReferenceTokens.premiumRadius,
              clipBehavior: Clip.hardEdge,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.hardEdge,
                children: [
                  ColoredBox(
                    color: AppColors.surfaceElevated.withValues(alpha: 0.96),
                  ),
                  const RepaintBoundary(child: HomeGemsStripPlate()),
                  const HomeGemsStripScrim(),
                  HomeGemsStripCopy(
                    title: GemsCopy.screenTitle,
                    balance: balance,
                    balanceLabel: GemsCopy.balanceLabel,
                    padding: pad,
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
