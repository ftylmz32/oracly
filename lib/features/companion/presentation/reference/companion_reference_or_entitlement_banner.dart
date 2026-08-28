/// Surfaces commerce entitlement states on OR — never invents membership.
library;

import 'package:flutter/material.dart';

import '../../../../core/design_system/oracly_chrome.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/reading_typography.dart';
import '../../../premium/models/premium_entitlement_state.dart';
import '../../copy/companion_copy.dart';

class CompanionReferenceOrEntitlementBanner extends StatelessWidget {
  const CompanionReferenceOrEntitlementBanner({
    super.key,
    required this.state,
    this.message,
  });

  final PremiumEntitlementState state;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final text = switch (state) {
      PremiumEntitlementState.pending => CompanionCopy.orEntitlementPending,
      PremiumEntitlementState.restoring => CompanionCopy.orEntitlementRestoring,
      PremiumEntitlementState.unavailable =>
        CompanionCopy.orEntitlementUnavailable,
      PremiumEntitlementState.error =>
        message?.trim().isNotEmpty == true
            ? message!.trim()
            : CompanionCopy.orEntitlementError,
      PremiumEntitlementState.unverified =>
        message?.trim().isNotEmpty == true
            ? message!.trim()
            : CompanionCopy.orEntitlementUnavailable,
      PremiumEntitlementState.active ||
      PremiumEntitlementState.inactive =>
        null,
    };
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: ReadingTypography.bodySmall(
          color: OraclyChrome.goldLight.withValues(alpha: 0.82),
        ),
      ),
    );
  }
}
