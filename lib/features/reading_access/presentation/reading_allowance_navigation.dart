/// The two doors an allowance surface may offer: read about Premium (no
/// purchase starts there by itself) and go home. Never a store sheet.
library;

import 'package:flutter/widgets.dart';

import '../../../shared/navigation/oracly_navigation.dart';
import '../../premium/presentation/reference/premium_reference_route.dart';

abstract final class ReadingAllowanceNavigation {
  ReadingAllowanceNavigation._();

  static Future<void> openPremium(BuildContext context) =>
      Navigator.of(context).push<void>(premiumScreenRoute<void>());

  static void goHome(BuildContext context) {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.popUntil((route) => route.isFirst);
    }
    OraclyNavigation.switchToTab(context, OraclyTab.home);
  }
}
