/// Home Premium banner copy — mirrors commerce state, never invents prices.
library;

import '../../../core/copy/premium_copy.dart';
import '../../premium/controllers/premium_status_controller.dart';

final class HomeReferencePremiumBannerState {
  const HomeReferencePremiumBannerState({
    required this.title,
    required this.body,
    required this.glowStrength,
    required this.maxBodyLines,
  });

  final String title;
  final String body;
  final double glowStrength;
  final int maxBodyLines;
}

abstract final class HomeReferencePremiumCopy {
  HomeReferencePremiumCopy._();

  static HomeReferencePremiumBannerState resolve(
    PremiumStatusController status,
  ) {
    if (status.isPremium) {
      return HomeReferencePremiumBannerState(
        title: PremiumCopy.ctaActive,
        body: PremiumCopy.activeBody,
        glowStrength: 1.06,
        maxBodyLines: 2,
      );
    }
    if (!status.purchaseConfigured) {
      return HomeReferencePremiumBannerState(
        title: PremiumCopy.ctaExplore,
        body: PremiumCopy.ctaUnavailable,
        glowStrength: 0.72,
        maxBodyLines: 2,
      );
    }
    if (status.busy) {
      return HomeReferencePremiumBannerState(
        title: PremiumCopy.homeBannerTitle,
        body: PremiumCopy.ctaBusy,
        glowStrength: 0.88,
        maxBodyLines: 1,
      );
    }
    return HomeReferencePremiumBannerState(
      title: PremiumCopy.homeBannerTitle,
      body: PremiumCopy.homeBannerBody,
      glowStrength: 1.1,
      maxBodyLines: 2,
    );
  }
}
