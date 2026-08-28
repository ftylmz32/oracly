/// Distinguishes Palm failures so UI can offer the right recovery.
library;

enum PalmAnalysisErrorKind {
  unsupportedImage,
  normalizeFailed,
  network,
  timeout,
  invalidResponse,
  unavailable,
  missingImage,
  unknown,
}

class PalmAnalysisError {
  const PalmAnalysisError(this.kind, this.message);

  final PalmAnalysisErrorKind kind;
  final String message;

  bool get canRetrySameImage => switch (kind) {
        PalmAnalysisErrorKind.network ||
        PalmAnalysisErrorKind.timeout ||
        PalmAnalysisErrorKind.invalidResponse ||
        PalmAnalysisErrorKind.unavailable ||
        PalmAnalysisErrorKind.unknown =>
          true,
        _ => false,
      };

  bool get needsNewPhoto => !canRetrySameImage;
}
