/// Quality failure taxonomy — safe to log, never raw text.
library;

enum AiOutputQualityCategory {
  unsupportedClaim,
  fakeMemory,
  deterministicFuture,
  medicalDiagnosis,
  fearManipulation,
  repetitiveFiller,
  emptyGeneric,
  implementationLanguage,
  mixedLanguage,
  brokenFormatting,
}
