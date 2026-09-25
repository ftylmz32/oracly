/// Frozen provider policy for Yıldızname Narrative V1.
library;

import '../versions.dart';

abstract final class YildiznameNarrativePolicy {
  YildiznameNarrativePolicy._();

  static const version = kYildiznamePolicyVersion;

  static const rules = <String>[
    'USE_ONLY_SUPPLIED_FACTS',
    'DO_NOT_CALCULATE_ASTRONOMY',
    'DO_NOT_INVENT_MEMORY',
    'DO_NOT_INVENT_PLACEMENTS',
    'DO_NOT_INVENT_HOUSES',
    'DO_NOT_INVENT_ASPECTS',
    'DO_NOT_TREAT_SYMBOLIC_INTERPRETATION_AS_CERTAINTY',
    'NO_DETERMINISTIC_FUTURE',
    'NO_FATALISM',
    'NO_MEDICAL_DIAGNOSIS',
    'NO_PREGNANCY_CERTAINTY',
    'NO_LEGAL_FINANCIAL_GUARANTEE',
    'NO_GUARANTEED_SOULMATE',
    'KARMIC_LANGUAGE_METAPHOR_ONLY',
  ];

  static Map<String, dynamic> toProviderJson() => {
        'version': version,
        'rules': List<String>.from(rules),
      };
}
