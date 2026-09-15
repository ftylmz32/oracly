/// Real success/failure of a runtime side-effect — never silently swallowed.
///
/// Used wherever a visible toggle (ambient music, SFX, daily notification)
/// triggers a real platform/plugin call: the caller must know whether the
/// effect actually applied, instead of assuming success because no
/// exception happened to propagate.
library;

enum OraclyApplyOutcome { success, failure }

extension OraclyApplyOutcomeX on OraclyApplyOutcome {
  bool get isSuccess => this == OraclyApplyOutcome.success;
  bool get isFailure => this == OraclyApplyOutcome.failure;
}
