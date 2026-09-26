/// Phase 8B — map execution failures to safe localized ResilienceCopy.
library;

import '../../../../core/copy/resilience_copy.dart';
import 'yildizname_live_execution.dart';

abstract final class YildiznameLiveErrorCopy {
  YildiznameLiveErrorCopy._();

  static String messageFor(YildiznameLiveExecutionKind kind) {
    return switch (kind) {
      YildiznameLiveExecutionKind.aiUnavailable =>
        ResilienceCopy.aiUnavailable,
      YildiznameLiveExecutionKind.generationFailed =>
        ResilienceCopy.interpretationFailed,
      YildiznameLiveExecutionKind.invalidEvidence =>
        ResilienceCopy.analysisUnavailable,
      YildiznameLiveExecutionKind.persistencePending =>
        ResilienceCopy.readingSaveFailed,
      YildiznameLiveExecutionKind.ownerUnavailable ||
      YildiznameLiveExecutionKind.ownerChanged ||
      YildiznameLiveExecutionKind.flagDisabled =>
        ResilienceCopy.temporaryFailure,
      YildiznameLiveExecutionKind.legacyLocal ||
      YildiznameLiveExecutionKind.ready =>
        ResilienceCopy.genericLoadFailed,
    };
  }

  static bool retryMeaningful(YildiznameLiveExecutionKind kind) {
    return switch (kind) {
      YildiznameLiveExecutionKind.generationFailed ||
      YildiznameLiveExecutionKind.persistencePending ||
      YildiznameLiveExecutionKind.invalidEvidence ||
      YildiznameLiveExecutionKind.aiUnavailable ||
      YildiznameLiveExecutionKind.ownerUnavailable ||
      YildiznameLiveExecutionKind.ownerChanged ||
      YildiznameLiveExecutionKind.flagDisabled =>
        true,
      YildiznameLiveExecutionKind.legacyLocal ||
      YildiznameLiveExecutionKind.ready =>
        false,
    };
  }
}
