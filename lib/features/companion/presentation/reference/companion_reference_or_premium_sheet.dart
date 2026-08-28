/// OR Premium gate sheet — OR paywall, not a generic subscription page.
library;

import 'package:flutter/material.dart';

import '../../../../shared/ui/oracly_bottom_sheet.dart';
import '../../copy/companion_copy.dart';
import 'companion_reference_or_paywall_host.dart';

abstract final class CompanionReferenceOrPremiumSheet {
  CompanionReferenceOrPremiumSheet._();

  static Future<void> show(BuildContext context) {
    return OraclyBottomSheet.show<void>(
      context,
      title: CompanionCopy.orPaywallTitle,
      child: const CompanionReferenceOrPaywallHost(
        compact: true,
        showHero: true,
        popOnGranted: true,
      ),
    );
  }
}
