/// Compact home Premium invitation. No invented prices or entitlements.
/// Opening this card only navigates to the Premium details screen.
library;

import '../../../core/copy/premium_copy.dart';
import '../../premium/controllers/premium_status_controller.dart';

final class HomeReferencePremiumBannerState {
  const HomeReferencePremiumBannerState({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.glowStrength,
    required this.maxBodyLines,
  });

  final String title;
  final String body;
  final String actionLabel;
  final double glowStrength;
  final int maxBodyLines;
}

abstract final class HomeReferencePremiumCopy {
  HomeReferencePremiumCopy._();

  static HomeReferencePremiumBannerState resolve(
    PremiumStatusController status,
  ) => resolveState(
    loaded: status.loaded,
    isPremium: status.isPremium,
    busy: status.busy,
    storeOffersPlans: status.storeOffersPlans,
  );

  /// View-state-only resolver: checking the store never promises a purchase.
  /// All paths link to details; none grants membership or starts payment.
  static HomeReferencePremiumBannerState resolveState({
    required bool loaded,
    required bool isPremium,
    required bool busy,
    required bool storeOffersPlans,
  }) {
    if (!loaded) {
      return HomeReferencePremiumBannerState(
        title: PremiumCopy.homeBannerTitle,
        body: PremiumCopy.loadingBody,
        actionLabel: PremiumCopy.ctaInspect,
        glowStrength: 0.8,
        maxBodyLines: 2,
      );
    }
    if (isPremium) {
      return HomeReferencePremiumBannerState(
        title: PremiumCopy.ctaActive,
        body: PremiumCopy.activeBody,
        actionLabel: PremiumCopy.homeMemberAction,
        glowStrength: 1.06,
        maxBodyLines: 2,
      );
    }
    if (busy) {
      return HomeReferencePremiumBannerState(
        title: PremiumCopy.homeBannerTitle,
        body: PremiumCopy.ctaBusy,
        actionLabel: PremiumCopy.ctaInspect,
        glowStrength: 0.88,
        maxBodyLines: 1,
      );
    }
    if (!storeOffersPlans) {
      return HomeReferencePremiumBannerState(
        title: PremiumCopy.homeBannerTitle,
        body: PremiumCopy.ctaUnavailable,
        actionLabel: PremiumCopy.ctaInspect,
        glowStrength: 0.72,
        maxBodyLines: 2,
      );
    }
    return HomeReferencePremiumBannerState(
      title: PremiumCopy.homeBannerTitle,
      body: PremiumCopy.homeBannerBody,
      actionLabel: PremiumCopy.homeInviteAction,
      glowStrength: 1.1,
      maxBodyLines: 2,
    );
  }
}
