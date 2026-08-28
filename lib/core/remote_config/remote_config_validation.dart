/// Result of validating a remote payload before any activation.
library;

import 'remote_config_defaults.dart';
import 'remote_config_snapshot.dart';

enum RemoteConfigValidationKind {
  /// Remote payload accepted (field-level fallbacks may still apply).
  accepted,

  /// No remote payload — use local defaults.
  missing,

  /// App cannot use this remote package — keep defaults.
  unsupported,

  /// Payload rejected wholesale — keep defaults.
  rejected,
}

class RemoteConfigValidation {
  const RemoteConfigValidation({
    required this.kind,
    required this.snapshot,
  });

  final RemoteConfigValidationKind kind;
  final RemoteConfigSnapshot snapshot;

  bool get isAccepted => kind == RemoteConfigValidationKind.accepted;

  static RemoteConfigValidation missing() => RemoteConfigValidation(
        kind: RemoteConfigValidationKind.missing,
        snapshot: RemoteConfigDefaults.snapshot,
      );

  static RemoteConfigValidation unsupported() => RemoteConfigValidation(
        kind: RemoteConfigValidationKind.unsupported,
        snapshot: RemoteConfigDefaults.snapshot,
      );

  static RemoteConfigValidation rejected() => RemoteConfigValidation(
        kind: RemoteConfigValidationKind.rejected,
        snapshot: RemoteConfigDefaults.snapshot,
      );

  static RemoteConfigValidation accepted(RemoteConfigSnapshot snapshot) =>
      RemoteConfigValidation(
        kind: RemoteConfigValidationKind.accepted,
        snapshot: snapshot,
      );
}
