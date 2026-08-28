/// Runtime access to the active remote config snapshot.
library;

import 'remote_config_defaults.dart';
import 'remote_config_snapshot.dart';

abstract final class RemoteConfigRuntime {
  RemoteConfigRuntime._();

  static RemoteConfigSnapshot _snapshot = RemoteConfigDefaults.snapshot;

  static RemoteConfigSnapshot get snapshot => _snapshot;

  static void bind(RemoteConfigSnapshot snapshot) {
    _snapshot = snapshot;
  }
}
