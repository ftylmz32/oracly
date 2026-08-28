/// Localized copy / copied labels for insight text.
library;

import '../l10n/l10n.dart';

abstract final class InsightCopyStrings {
  InsightCopyStrings._();

  static String get action => OraclyL10n.t('insight.copy');
  static String get copied => OraclyL10n.t('insight.copied');
}
