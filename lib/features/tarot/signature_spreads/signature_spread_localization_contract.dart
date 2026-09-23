/// Phase 5C — pure localization completeness for launch catalog keys.
library;

import '../../../core/l10n/app_string_tables.dart';
import 'signature_spread_definition.dart';

enum SignatureLocalizationViolation {
  missingKey,
  emptyValue,
  rawKeyFallback,
}

class SignatureLocalizationIssue {
  const SignatureLocalizationIssue({
    required this.key,
    required this.languageCode,
    required this.violation,
  });

  final String key;
  final String languageCode;
  final SignatureLocalizationViolation violation;
}

class SignatureLocalizationResult {
  const SignatureLocalizationResult(this.issues);
  final List<SignatureLocalizationIssue> issues;
  bool get isValid => issues.isEmpty;
}

abstract final class SignatureSpreadLocalizationContract {
  SignatureSpreadLocalizationContract._();

  static const languages = <String>['tr', 'en', 'ru'];

  static SignatureLocalizationResult validateDefinition(
    SignatureSpreadDefinition definition,
  ) {
    final keys = <String>{
      definition.displayTitleKey,
      definition.displayBlurbKey,
      definition.purposeKey,
      if (definition.bannerKey != null) definition.bannerKey!,
      for (final p in definition.positions) ...[
        p.displayLabelKey,
        p.guidingQuestionKey,
      ],
    };
    return validateKeys(keys);
  }

  static SignatureLocalizationResult validateCatalog(
    List<SignatureSpreadDefinition> catalog,
  ) {
    final keys = <String>{};
    for (final d in catalog) {
      keys.add(d.displayTitleKey);
      keys.add(d.displayBlurbKey);
      keys.add(d.purposeKey);
      if (d.bannerKey != null) keys.add(d.bannerKey!);
      for (final p in d.positions) {
        keys.add(p.displayLabelKey);
        keys.add(p.guidingQuestionKey);
      }
    }
    return validateKeys(keys);
  }

  static SignatureLocalizationResult validateKeys(Set<String> keys) {
    final out = <SignatureLocalizationIssue>[];
    for (final key in keys) {
      for (final lang in languages) {
        final value = AppStringTables.lookup(lang, key);
        if (value == null) {
          out.add(
            SignatureLocalizationIssue(
              key: key,
              languageCode: lang,
              violation: SignatureLocalizationViolation.missingKey,
            ),
          );
          continue;
        }
        if (value.trim().isEmpty) {
          out.add(
            SignatureLocalizationIssue(
              key: key,
              languageCode: lang,
              violation: SignatureLocalizationViolation.emptyValue,
            ),
          );
        }
        if (value == key) {
          out.add(
            SignatureLocalizationIssue(
              key: key,
              languageCode: lang,
              violation: SignatureLocalizationViolation.rawKeyFallback,
            ),
          );
        }
      }
    }
    return SignatureLocalizationResult(
      List<SignatureLocalizationIssue>.unmodifiable(out),
    );
  }
}
