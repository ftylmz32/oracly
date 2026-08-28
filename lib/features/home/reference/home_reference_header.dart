/// Home header — emblem+wordmark left, Premium pill right (no menu/gems).
library;

import 'package:flutter/material.dart';

import '../../../core/accessibility/oracly_a11y.dart';
import '../../../core/brand/oracly_brand_mark.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/navigation/oracly_navigation_service.dart';
import '../../../shared/widgets/oracly_pressable.dart';
import 'home_reference_scope.dart';

class HomeReferenceHeader extends StatelessWidget {
  /// Legacy — not shown on master Home header.
  static const tagline = '';

  const HomeReferenceHeader({
    super.key,
    this.onPremiumTap,
  });

  final VoidCallback? onPremiumTap;

  @override
  Widget build(BuildContext context) {
    final layout = HomeReferenceScope.maybeOf(context);
    final height = layout?.headerHeight ?? 48;
    final titleSize = layout?.greetingTitleSize ?? 18;

    return SizedBox(
      height: height,
      child: Row(
        children: [
          Expanded(
            child: OraclyA11y.chromeTextScale(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const ExcludeSemantics(
                    child: OraclyBrandMark(size: 28),
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Semantics(
                      header: true,
                      label: 'ORACLY',
                      child: Text(
                        'ORACLY',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.headingM.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: 3.2,
                          color: OraclyA11y.goldReadable(
                            OraclyChrome.goldPrimary,
                          ),
                          height: 1,
                          fontSize: titleSize,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _HomePremiumPill(
            onTap: onPremiumTap ??
                () => OraclyNavigationService.openPremium(context),
          ),
        ],
      ),
    );
  }
}

class _HomePremiumPill extends StatelessWidget {
  const _HomePremiumPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = OraclyL10n.t('home.header.premium');
    return Semantics(
      button: true,
      label: label,
      child: OraclyPressable(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: OraclyA11y.minTouchTarget),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: OraclyChrome.violet.withValues(alpha: 0.28),
              border: Border.all(
                color: OraclyChrome.gold.withValues(alpha: 0.42),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium_rounded,
                    size: 16,
                    color: OraclyA11y.goldReadable(OraclyChrome.goldLight),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      color: OraclyA11y.goldReadable(OraclyChrome.goldLight),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
