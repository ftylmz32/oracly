/// Optional evidence flags for context-sensitive checks.
library;

class AiOutputQualityContext {
  const AiOutputQualityContext({
    this.hasMemoryEvidence = false,
    this.hasVisualEvidence = false,
    this.localeCode = 'tr',
  });

  final bool hasMemoryEvidence;
  final bool hasVisualEvidence;
  final String localeCode;
}
