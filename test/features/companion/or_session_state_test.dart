/// OR session state resolver — chamber stays usable in every state.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/models/companion_state.dart';
import 'package:oracly_new/features/companion/models/or_session_state.dart';
import 'package:oracly_new/features/companion/services/or_session_resolver.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';

void main() {
  OrSessionState resolve({
    PremiumEntitlementState entitlement = PremiumEntitlementState.active,
    CompanionLinkStatus link = CompanionLinkStatus.online,
    AiFailureKind? lastFailure,
    bool voiceUnavailable = false,
    bool bootstrapping = false,
    bool chamberEmpty = true,
    bool busy = false,
    bool networkRetry = false,
  }) =>
      OrSessionResolver.resolve(
        entitlement: entitlement,
        link: link,
        lastFailure: lastFailure,
        voiceUnavailable: voiceUnavailable,
        bootstrapping: bootstrapping,
        chamberEmpty: chamberEmpty,
        busy: busy,
        networkRetry: networkRetry,
      ).state;

  test('free user stays gated with preview', () {
    final p = OrSessionResolver.resolve(
      entitlement: PremiumEntitlementState.inactive,
      link: CompanionLinkStatus.online,
      voiceUnavailable: false,
    );
    expect(p.state, OrSessionState.free);
    expect(p.canCompose, isFalse);
    expect(p.showPreview, isTrue);
    expect(p.isGated, isTrue);
  });

  test('unavailable store entitlement never opens composer', () {
    final empty = OrSessionResolver.resolve(
      entitlement: PremiumEntitlementState.unavailable,
      link: CompanionLinkStatus.online,
      voiceUnavailable: false,
      chamberEmpty: true,
    );
    expect(empty.canCompose, isFalse);
    expect(empty.canUseMic, isFalse);
    expect(empty.isGated, isTrue);

    final scrolled = OrSessionResolver.resolve(
      entitlement: PremiumEntitlementState.unavailable,
      link: CompanionLinkStatus.online,
      voiceUnavailable: false,
      chamberEmpty: false,
    );
    expect(scrolled.canCompose, isFalse);
    expect(scrolled.showPaywallDock, isTrue);
  });

  test('healthy path is success', () {
    expect(resolve(), OrSessionState.success);
    final p = OrSessionResolver.resolve(
      entitlement: PremiumEntitlementState.active,
      link: CompanionLinkStatus.online,
      voiceUnavailable: false,
    );
    expect(p.canCompose, isTrue);
    expect(p.canUseMic, isTrue);
    expect(p.showStatusStrip, isFalse);
  });

  test('purchase pending beats free/premium features', () {
    expect(
      resolve(entitlement: PremiumEntitlementState.pending),
      OrSessionState.purchasePending,
    );
    expect(
      resolve(entitlement: PremiumEntitlementState.restoring),
      OrSessionState.purchasePending,
    );
  });

  test('offline keeps compose for retry', () {
    final p = OrSessionResolver.resolve(
      entitlement: PremiumEntitlementState.active,
      link: CompanionLinkStatus.offline,
      voiceUnavailable: false,
    );
    expect(p.state, OrSessionState.offline);
    expect(p.canCompose, isTrue);
    expect(p.canRetry, isTrue);
    expect(p.showStatusStrip, isTrue);
  });

  test('reconnecting and retrying stay accessible without fake success', () {
    final reconnecting = OrSessionResolver.resolve(
      entitlement: PremiumEntitlementState.active,
      link: CompanionLinkStatus.reconnecting,
      voiceUnavailable: false,
    );
    expect(reconnecting.state, OrSessionState.reconnecting);
    expect(reconnecting.canCompose, isTrue);
    expect(reconnecting.canRetry, isFalse);
    expect(reconnecting.connecting, isTrue);

    final retrying = OrSessionResolver.resolve(
      entitlement: PremiumEntitlementState.active,
      link: CompanionLinkStatus.reconnecting,
      lastFailure: AiFailureKind.network,
      voiceUnavailable: false,
      busy: true,
      networkRetry: true,
    );
    expect(retrying.state, OrSessionState.retrying);
    expect(retrying.canCompose, isTrue);
    expect(retrying.canRetry, isFalse);
    expect(retrying.statusLine, CompanionCopy.retrying);
  });

  test('typed AI failures map cleanly', () {
    expect(
      resolve(lastFailure: AiFailureKind.unauthorized),
      OrSessionState.sessionExpired,
    );
    expect(
      resolve(lastFailure: AiFailureKind.rateLimit),
      OrSessionState.rateLimited,
    );
    expect(
      resolve(lastFailure: AiFailureKind.providerError),
      OrSessionState.providerUnavailable,
    );
    expect(
      resolve(lastFailure: AiFailureKind.network),
      OrSessionState.offline,
    );
    final provider = OrSessionResolver.resolve(
      entitlement: PremiumEntitlementState.active,
      link: CompanionLinkStatus.online,
      lastFailure: AiFailureKind.providerError,
      voiceUnavailable: false,
    );
    expect(provider.canRetry, isTrue);
    expect(provider.showStatusStrip, isTrue);
  });

  test('voice unavailable demotes only voice, not text', () {
    final p = OrSessionResolver.resolve(
      entitlement: PremiumEntitlementState.active,
      link: CompanionLinkStatus.online,
      voiceUnavailable: true,
    );
    expect(p.state, OrSessionState.voiceUnavailable);
    expect(p.canCompose, isTrue);
    expect(p.canUseMic, isTrue);
  });

  test('access gates beat reachability noise for free', () {
    expect(
      resolve(
        entitlement: PremiumEntitlementState.inactive,
        link: CompanionLinkStatus.offline,
        lastFailure: AiFailureKind.rateLimit,
      ),
      OrSessionState.free,
    );
  });
}
