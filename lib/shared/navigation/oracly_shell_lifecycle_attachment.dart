/// Testable single shell lifecycle observer attachment.
library;

import 'package:flutter/widgets.dart';

/// Ensures exactly one [WidgetsBindingObserver] is registered per attachment
/// instance. Rebuild-safe (idempotent [attach]) and dispose-safe ([detach]).
class OraclyShellLifecycleAttachment with WidgetsBindingObserver {
  OraclyShellLifecycleAttachment({
    required this.onLifecycle,
    WidgetsBinding? binding,
  }) : _binding = binding ?? WidgetsBinding.instance;

  final void Function(AppLifecycleState state) onLifecycle;
  final WidgetsBinding _binding;
  bool _attached = false;

  bool get isAttached => _attached;

  void attach() {
    if (_attached) return;
    _binding.addObserver(this);
    _attached = true;
  }

  void detach() {
    if (!_attached) return;
    _binding.removeObserver(this);
    _attached = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_attached) return;
    onLifecycle(state);
  }
}
