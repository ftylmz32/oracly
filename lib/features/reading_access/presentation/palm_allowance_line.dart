/// El Falı daily allowance in the palm chamber's own voice: no frame, a
/// fine gold rule and cream lines between the hand choice and the capture
/// invite; the "used today" view is a calm resting hand, never a paywall.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_spacing.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/reading_typography.dart';
import '../../palm/presentation/palm_hand_glyph.dart';
import '../../palm/presentation/palm_quiet_link.dart';
import '../../palm/presentation/palm_tokens.dart';
import '../../premium/providers/premium_providers.dart';
import '../copy/freemium_copy.dart';
import '../models/reading_allowance.dart';
import 'reading_allowance_navigation.dart';

class PalmAllowanceLine extends ConsumerWidget {
  const PalmAllowanceLine({super.key, required this.view});

  final ReadingAllowanceView view;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (String lead, String? second) = switch (view.status) {
      ReadingAllowanceStatus.premium => (
        FreemiumCopy.premiumTitle(view.kind),
        null,
      ),
      ReadingAllowanceStatus.free => (
        FreemiumCopy.freeTitle(view.kind),
        FreemiumCopy.premiumTitle(view.kind),
      ),
      ReadingAllowanceStatus.checking => (
        FreemiumCopy.freeTitle(view.kind),
        FreemiumCopy.checking,
      ),
      ReadingAllowanceStatus.checkFailed => (FreemiumCopy.checkFailed, null),
      ReadingAllowanceStatus.usedToday => (
        FreemiumCopy.usedTitle(view.kind, premium: view.premium),
        null,
      ),
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GoldRule(premium: view.status == ReadingAllowanceStatus.premium),
        SizedBox(height: AppSpacing.s4),
        Text(
          lead,
          textAlign: TextAlign.center,
          style: ReadingTypography.label(
            color: PalmTokens.cream.withValues(alpha: 0.92),
          ),
        ),
        if (second != null) ...[
          SizedBox(height: AppSpacing.s4),
          Text(
            second,
            textAlign: TextAlign.center,
            style: ReadingTypography.footnote(
              color: OraclyChrome.goldLight.withValues(alpha: 0.78),
            ),
          ),
        ],
        if (view.status == ReadingAllowanceStatus.checkFailed)
          PalmQuietLink(
            label: FreemiumCopy.retry,
            onTap: () => ref.read(premiumStatusProvider).refresh(),
          ),
      ],
    );
  }
}

/// Shown only after the server's own daily-quota answer for Palm.
class PalmAllowanceUsedView extends StatelessWidget {
  const PalmAllowanceUsedView({
    super.key,
    required this.view,
    required this.onRecheck,
    required this.onBack,
  });

  final ReadingAllowanceView view;
  final VoidCallback onRecheck;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ExcludeSemantics(
              child: Center(child: PalmHandGlyph(left: false, size: 44)),
            ),
            SizedBox(height: AppSpacing.s16),
            Semantics(
              header: true,
              child: Text(
                FreemiumCopy.usedTitle(view.kind, premium: view.premium),
                textAlign: TextAlign.center,
                style: ReadingTypography.cardTitle(color: PalmTokens.cream),
              ),
            ),
            SizedBox(height: AppSpacing.s8),
            Text(
              FreemiumCopy.usedBody,
              textAlign: TextAlign.center,
              style: ReadingTypography.secondary(
                color: PalmTokens.cream.withValues(alpha: 0.78),
              ),
            ),
            if (!view.premium) ...[
              SizedBox(height: AppSpacing.s16),
              const _GoldRule(premium: false),
              SizedBox(height: AppSpacing.s8),
              Text(
                FreemiumCopy.usedPremiumOffer,
                textAlign: TextAlign.center,
                style: ReadingTypography.footnote(
                  color: OraclyChrome.goldLight.withValues(alpha: 0.82),
                ),
              ),
              PalmQuietLink(
                label: FreemiumCopy.seePremium,
                onTap: () => ReadingAllowanceNavigation.openPremium(context),
              ),
            ],
            SizedBox(height: AppSpacing.s8),
            PalmQuietLink(label: FreemiumCopy.recheck, onTap: onRecheck),
            PalmQuietLink(label: FreemiumCopy.backHome, onTap: onBack),
          ],
        ),
      ),
    );
  }
}

class _GoldRule extends StatelessWidget {
  const _GoldRule({required this.premium});

  final bool premium;

  @override
  Widget build(BuildContext context) {
    final line = Container(
      width: 28,
      height: 1,
      color: OraclyChrome.gold.withValues(alpha: 0.42),
    );
    return ExcludeSemantics(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: premium
                ? Text(
                    FreemiumCopy.premiumBadge,
                    style: ReadingTypography.micro(color: OraclyChrome.gold),
                  )
                : Icon(
                    Icons.circle,
                    size: 4,
                    color: OraclyChrome.gold.withValues(alpha: 0.7),
                  ),
          ),
          line,
        ],
      ),
    );
  }
}
