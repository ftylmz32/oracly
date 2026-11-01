/// Kahve Falı daily allowance — one framed, quiet plate under the cup hero
/// (policy, Premium or checking), and the "used today" plate shown only
/// after the server answered the daily quota. No price, no buy button.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_quiet_link.dart';
import '../../premium/providers/premium_providers.dart';
import '../copy/freemium_copy.dart';
import '../models/reading_allowance.dart';
import 'reading_allowance_navigation.dart';

class CoffeeAllowancePanel extends ConsumerWidget {
  const CoffeeAllowancePanel({super.key, required this.view});

  final ReadingAllowanceView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final children = switch (view.status) {
      ReadingAllowanceStatus.premium => [
        const _PremiumSeal(),
        SizedBox(height: AppSpacing.s8),
        Text(
          FreemiumCopy.premiumTitle(view.kind),
          textAlign: TextAlign.center,
          style: ReadingTypography.label(color: OraclyChrome.cream),
        ),
      ],
      ReadingAllowanceStatus.free => [
        Text(
          FreemiumCopy.freeTitle(view.kind),
          textAlign: TextAlign.center,
          style: ReadingTypography.label(color: OraclyChrome.cream),
        ),
        SizedBox(height: AppSpacing.s4),
        Text(
          FreemiumCopy.freeNote,
          textAlign: TextAlign.center,
          style: ReadingTypography.footnote(),
        ),
        const _Rule(),
        Text(
          FreemiumCopy.premiumTitle(view.kind),
          textAlign: TextAlign.center,
          style: ReadingTypography.footnote(
            color: OraclyChrome.goldLight.withValues(alpha: 0.86),
          ),
        ),
      ],
      ReadingAllowanceStatus.checking => [
        Text(
          FreemiumCopy.freeTitle(view.kind),
          textAlign: TextAlign.center,
          style: ReadingTypography.label(color: OraclyChrome.cream),
        ),
        SizedBox(height: AppSpacing.s4),
        Text(
          FreemiumCopy.checking,
          textAlign: TextAlign.center,
          style: ReadingTypography.footnote(),
        ),
      ],
      ReadingAllowanceStatus.checkFailed => [
        Text(
          FreemiumCopy.checkFailed,
          textAlign: TextAlign.center,
          style: ReadingTypography.footnote(color: OraclyChrome.cream),
        ),
        OraclyQuietLink(
          label: FreemiumCopy.retry,
          onTap: () => ref.read(premiumStatusProvider).refresh(),
        ),
      ],
      // The used plate replaces this panel; never both.
      ReadingAllowanceStatus.usedToday => const <Widget>[],
    };
    if (children.isEmpty) return const SizedBox.shrink();
    return _Plate(
      highlighted: view.status == ReadingAllowanceStatus.premium,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

/// Shown only after the server's own daily-quota answer.
class CoffeeAllowanceUsedCard extends StatelessWidget {
  const CoffeeAllowanceUsedCard({
    super.key,
    required this.view,
    required this.onRecheck,
  });

  final ReadingAllowanceView view;
  final VoidCallback onRecheck;

  @override
  Widget build(BuildContext context) {
    return _Plate(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.nights_stay_outlined,
            size: 22,
            color: OraclyChrome.gold.withValues(alpha: 0.82),
          ),
          SizedBox(height: AppSpacing.s8),
          Semantics(
            header: true,
            child: Text(
              FreemiumCopy.usedTitle(view.kind, premium: view.premium),
              textAlign: TextAlign.center,
              style: ReadingTypography.cardTitle(color: OraclyChrome.cream),
            ),
          ),
          SizedBox(height: AppSpacing.s8),
          Text(
            FreemiumCopy.usedBody,
            textAlign: TextAlign.center,
            style: ReadingTypography.secondary(),
          ),
          if (!view.premium) ...[
            const _Rule(),
            Text(
              FreemiumCopy.usedPremiumOffer,
              textAlign: TextAlign.center,
              style: ReadingTypography.footnote(
                color: OraclyChrome.goldLight.withValues(alpha: 0.86),
              ),
            ),
            OraclyQuietLink(
              label: FreemiumCopy.seePremium,
              onTap: () => ReadingAllowanceNavigation.openPremium(context),
            ),
          ],
          OraclyQuietLink(
            label: FreemiumCopy.recheck,
            muted: true,
            onTap: onRecheck,
          ),
        ],
      ),
    );
  }
}

class _Plate extends StatelessWidget {
  const _Plate({required this.child, this.highlighted = false});

  final Widget child;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        borderRadius: OraclyChrome.cardRadius,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            OraclyChrome.deepNavy.withValues(alpha: 0.72),
            OraclyChrome.cardSurface.withValues(alpha: 0.5),
          ],
        ),
        border: Border.all(
          color: OraclyChrome.gold.withValues(
            alpha: highlighted
                ? OraclyChrome.borderEmphasis
                : OraclyChrome.borderHairline,
          ),
        ),
      ),
      child: child,
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.s8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 96),
          child: Container(
            height: 1,
            color: OraclyChrome.gold.withValues(alpha: 0.28),
          ),
        ),
      ),
    );
  }
}

class _PremiumSeal extends StatelessWidget {
  const _PremiumSeal();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          borderRadius: OraclyChrome.pillRadius,
          border: Border.all(
            color: OraclyChrome.gold.withValues(alpha: OraclyChrome.borderEmphasis),
          ),
        ),
        child: Text(
          FreemiumCopy.premiumBadge,
          style: ReadingTypography.micro(color: OraclyChrome.gold),
        ),
      ),
    );
  }
}
