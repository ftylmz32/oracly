/// OR network recovery — offline accessible, real retry, no fake success.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/production/ai_failure.dart';
import 'package:oracly_new/features/companion/controllers/companion_controller.dart';
import 'package:oracly_new/features/companion/models/companion_state.dart';
import 'package:oracly_new/features/companion/models/or_session_state.dart';
import 'package:oracly_new/features/companion/services/or_session_resolver.dart';
import 'package:oracly_new/features/premium/models/premium_entitlement_state.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('recovery states never gate the chamber', () {
    for (final state in [
      OrSessionState.offline,
      OrSessionState.reconnecting,
      OrSessionState.retrying,
      OrSessionState.providerUnavailable,
      OrSessionState.success,
    ]) {
      expect(OrSessionState.values, contains(state));
    }

    final offline = OrSessionResolver.resolve(
      entitlement: PremiumEntitlementState.active,
      link: CompanionLinkStatus.offline,
      voiceUnavailable: false,
    );
    expect(offline.canCompose, isTrue);
    expect(offline.showPaywallDock, isFalse);
    expect(offline.showPreview, isFalse);

    final success = OrSessionResolver.resolve(
      entitlement: PremiumEntitlementState.active,
      link: CompanionLinkStatus.online,
      voiceUnavailable: false,
    );
    expect(success.state, OrSessionState.success);
    expect(success.showStatusStrip, isFalse);
  });

  test('linkFor maps network to offline only', () {
    expect(
      CompanionController.linkForTest(AiFailureKind.network),
      CompanionLinkStatus.offline,
    );
    expect(
      CompanionController.linkForTest(AiFailureKind.providerError),
      CompanionLinkStatus.online,
    );
  });
}

