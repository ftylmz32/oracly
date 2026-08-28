/// Locale-facing OR identity — always [OrPersonaContract], never a second persona.
library;

import '../l10n/l10n.dart';
import 'or_persona_contract.dart';

abstract final class OrPromptLocale {
  OrPromptLocale._();

  static String get code => OraclyL10n.code;

  static String get systemIdentity => OrPersonaContract.systemIdentity;

  static String get epistemic => OrPersonaContract.epistemic;

  static String get stance => OrPersonaContract.stance;
}
