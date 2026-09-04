/// Resolves OR session presentation from commerce + link + failure + voice.
library;

import '../../ai/production/ai_failure.dart';
import '../../premium/models/premium_entitlement_state.dart';
import '../copy/companion_copy.dart';
import '../models/companion_state.dart';
import '../models/or_session_presentation.dart';
import '../models/or_session_state.dart';

abstract final class OrSessionResolver {
  OrSessionResolver._();

  static OrSessionPresentation resolve({
    required PremiumEntitlementState entitlement,
    required CompanionLinkStatus link,
    AiFailureKind? lastFailure,
    required bool voiceUnavailable,
    bool bootstrapping = false,
    bool chamberEmpty = true,
    bool busy = false,
    bool networkRetry = false,
    bool contextualDeepenAllowed = false,
    /// Commerce entitlement OR an active reviewer grant. Defaults to
    /// [entitlement]'s own commerce-only flag when not supplied, so every
    /// existing caller keeps its exact prior behavior. Callers with a live
    /// [PremiumStatusController] should always pass its `isPremium` here —
    /// review access must unlock composing the same way Premium does.
    bool? premiumUnlocked,
  }) {
    final unlocked = premiumUnlocked ?? entitlement.allowsPremiumFeatures;
    // A lingering commerce pending/restoring state must never block someone
    // who already has an effective Premium unlock (real entitlement or
    // review access) — otherwise a stuck in-app-purchase query can paywall
    // a reviewer even though PremiumStatus already says active.
    if (!unlocked &&
        (entitlement == PremiumEntitlementState.pending ||
            entitlement == PremiumEntitlementState.restoring)) {
      return OrSessionPresentation(
        state: OrSessionState.purchasePending,
        canCompose: false,
        canUseMic: false,
        showPreview: chamberEmpty,
        showPaywallDock: !chamberEmpty,
        statusLine: entitlement == PremiumEntitlementState.restoring
            ? CompanionCopy.orEntitlementRestoring
            : CompanionCopy.orEntitlementPending,
      );
    }

    if (!unlocked) {
      if (contextualDeepenAllowed) {
        return OrSessionPresentation(
          state: OrSessionState.free,
          canCompose: true,
          canUseMic: false,
          showPreview: false,
          showPaywallDock: false,
          statusLine: CompanionCopy.firstReadingDeepenHint,
        );
      }
      return OrSessionPresentation(
        state: OrSessionState.free,
        canCompose: false,
        canUseMic: false,
        showPreview: chamberEmpty,
        showPaywallDock: !chamberEmpty,
      );
    }

    // In-flight recovery — chamber stays open; no fake reply; no retry spam.
    if (busy &&
        (networkRetry ||
            link == CompanionLinkStatus.reconnecting ||
            lastFailure == AiFailureKind.network ||
            lastFailure == AiFailureKind.providerError ||
            lastFailure == AiFailureKind.timeout ||
            lastFailure == AiFailureKind.noConfiguration ||
            lastFailure == AiFailureKind.invalidResponse ||
            lastFailure == AiFailureKind.rateLimit ||
            lastFailure == AiFailureKind.authPending ||
            lastFailure == AiFailureKind.appCheck ||
            lastFailure == AiFailureKind.localPersistence)) {
      return OrSessionPresentation(
        state: OrSessionState.retrying,
        canCompose: true,
        canUseMic: false,
        showPreview: false,
        showPaywallDock: false,
        statusLine: CompanionCopy.retrying,
        canRetry: false,
        connecting: true,
      );
    }

    if (bootstrapping ||
        link == CompanionLinkStatus.connecting ||
        link == CompanionLinkStatus.reconnecting) {
      return OrSessionPresentation(
        state: OrSessionState.reconnecting,
        canCompose: true,
        canUseMic: !voiceUnavailable,
        showPreview: false,
        showPaywallDock: false,
        statusLine: link == CompanionLinkStatus.reconnecting
            ? CompanionCopy.reconnecting
            : CompanionCopy.connecting,
        canRetry: false,
        connecting: true,
      );
    }

    if (lastFailure == AiFailureKind.authPending) {
      return OrSessionPresentation(
        state: OrSessionState.reconnecting,
        canCompose: true,
        canUseMic: false,
        showPreview: false,
        showPaywallDock: false,
        statusLine: CompanionCopy.connecting,
        canRetry: true,
        connecting: true,
      );
    }

    if (lastFailure == AiFailureKind.unauthorized ||
        lastFailure == AiFailureKind.appCheck) {
      return OrSessionPresentation(
        state: OrSessionState.sessionExpired,
        canCompose: true,
        canUseMic: false,
        showPreview: false,
        showPaywallDock: false,
        statusLine: CompanionCopy.connectionError,
        canRetry: true,
      );
    }

    if (link == CompanionLinkStatus.offline ||
        lastFailure == AiFailureKind.network) {
      return OrSessionPresentation(
        state: OrSessionState.offline,
        canCompose: true,
        canUseMic: false,
        showPreview: false,
        showPaywallDock: false,
        statusLine: CompanionCopy.offline,
        canRetry: true,
      );
    }

    if (lastFailure == AiFailureKind.rateLimit) {
      return OrSessionPresentation(
        state: OrSessionState.rateLimited,
        canCompose: true,
        canUseMic: !voiceUnavailable,
        showPreview: false,
        showPaywallDock: false,
        statusLine: CompanionCopy.connectionError,
        canRetry: true,
      );
    }

    if (lastFailure == AiFailureKind.providerError ||
        lastFailure == AiFailureKind.noConfiguration ||
        lastFailure == AiFailureKind.timeout ||
        lastFailure == AiFailureKind.invalidResponse) {
      return OrSessionPresentation(
        state: OrSessionState.providerUnavailable,
        canCompose: true,
        canUseMic: !voiceUnavailable,
        showPreview: false,
        showPaywallDock: false,
        statusLine: CompanionCopy.providerUnavailable,
        canRetry: true,
      );
    }

    if (lastFailure == AiFailureKind.localPersistence) {
      return OrSessionPresentation(
        state: OrSessionState.saveFailed,
        canCompose: true,
        canUseMic: !voiceUnavailable,
        showPreview: false,
        showPaywallDock: false,
        statusLine: CompanionCopy.saveFailed,
        canRetry: true,
      );
    }

    if (voiceUnavailable) {
      return OrSessionPresentation(
        state: OrSessionState.voiceUnavailable,
        canCompose: true,
        canUseMic: true,
        showPreview: false,
        showPaywallDock: false,
        statusLine: CompanionCopy.voiceOutputUnavailable,
      );
    }

    return const OrSessionPresentation(
      state: OrSessionState.success,
      canCompose: true,
      canUseMic: true,
      showPreview: false,
      showPaywallDock: false,
    );
  }
}
