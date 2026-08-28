/// Fetches and validates remote config; activates only at safe boundaries.
library;

import '../feature_flags/feature_flag_runtime.dart';
import 'remote_config_activation.dart';
import 'remote_config_defaults.dart';
import 'remote_config_pending_store.dart';
import 'remote_config_port.dart';
import 'remote_config_runtime.dart';
import 'remote_config_snapshot.dart';
import 'remote_config_validation.dart';
import 'remote_config_validator.dart';

class RemoteConfigService {
  RemoteConfigService({
    required this.port,
    this.pendingStore,
  }) {
    final staged = pendingStore?.load();
    if (staged != null) _pending = staged;
    _bind(_snapshot);
  }

  final RemoteConfigPort port;
  final RemoteConfigPendingStore? pendingStore;
  RemoteConfigSnapshot _snapshot = RemoteConfigDefaults.snapshot;
  RemoteConfigSnapshot? _pending;
  RemoteConfigValidationKind? _lastValidation;

  RemoteConfigSnapshot get snapshot => _snapshot;
  RemoteConfigSnapshot? get pending => _pending;
  RemoteConfigValidationKind? get lastValidation => _lastValidation;
  bool get hasPending => _pending != null;

  /// Session start: promote staged config, then refresh for the *next* session.
  Future<void> beginSession() async {
    await activatePending();
    await refresh(activation: RemoteConfigActivation.nextSession);
  }

  /// Controlled apply — call only when not mid-critical interaction.
  Future<void> controlledRefresh() async {
    await refresh(activation: RemoteConfigActivation.controlled);
  }

  Future<RemoteConfigValidation> refresh({
    RemoteConfigActivation activation = RemoteConfigActivation.nextSession,
  }) async {
    RemoteConfigValidation validation;
    try {
      validation = RemoteConfigValidator.validate(await port.fetch());
    } catch (_) {
      validation = RemoteConfigValidation.missing();
    }
    _lastValidation = validation.kind;

    if (!validation.isAccepted) {
      return validation;
    }

    switch (activation) {
      case RemoteConfigActivation.nextSession:
        await _stage(validation.snapshot);
      case RemoteConfigActivation.sessionBoundary:
      case RemoteConfigActivation.controlled:
        await _stage(validation.snapshot);
        await activatePending();
    }
    return validation;
  }

  Future<bool> activatePending() async {
    final next = _pending;
    if (next == null) return false;
    _snapshot = next;
    _pending = null;
    await pendingStore?.clear();
    _bind(_snapshot);
    return true;
  }

  Future<void> _stage(RemoteConfigSnapshot snapshot) async {
    _pending = snapshot;
    await pendingStore?.save(snapshot);
  }

  void _bind(RemoteConfigSnapshot snapshot) {
    RemoteConfigRuntime.bind(snapshot);
    FeatureFlagRuntime.refreshFromRemote(snapshot.featureFlags);
  }
}
