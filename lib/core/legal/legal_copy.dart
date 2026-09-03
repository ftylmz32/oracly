/// Localized legal / subscription disclosure copy.
library;

import '../domain/models/premium_plan.dart';
import '../l10n/l10n.dart';

abstract final class LegalCopy {
  LegalCopy._();

  static String _t(String key) => OraclyL10n.t(key);

  static String get section => _t('legal.section');
  static String get privacyPolicy => _t('legal.privacy_policy');
  static String get termsOfUse => _t('legal.terms_of_use');
  static String get manageSubscription => _t('legal.manage_subscription');
  static String get missingUrl => _t('legal.missing_url');
  static String get opensExternally => _t('legal.opens_externally');
  static String get launchFailed => _t('legal.launch_failed');
  static String get manageUnavailable => _t('legal.manage_unavailable');
  static String get storeBillingNote => _t('legal.store_billing_note');
  static String get cancelNote => _t('legal.cancel_note');
  static String get restoreNote => _t('legal.restore_note');

  static String planDisclosure(PremiumPlanKind kind) => switch (kind) {
        PremiumPlanKind.monthly => _t('legal.disclosure.monthly'),
        PremiumPlanKind.yearly => _t('legal.disclosure.yearly'),
        PremiumPlanKind.lifetime => _t('legal.disclosure.lifetime'),
      };
}