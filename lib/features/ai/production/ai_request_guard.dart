/// Debounce + in-flight coalesce + burst cap for expensive AI calls.
library;

import 'package:flutter/foundation.dart';

import 'ai_failure.dart';
import 'ai_outcome.dart';
import 'ai_request_abuse_policy.dart';

class AiRequestGuard {
  AiRequestGuard();

  static final AiRequestGuard shared = AiRequestGuard();

  final Map<String, Future<Object?>> _inflight = {};
  final Map<String, DateTime> _lastOk = {};
  final Map<AiRequestKind, List<DateTime>> _burst = {};

  bool isBusy([String? key]) {
    if (key == null) return _inflight.isNotEmpty;
    return _inflight.containsKey(key);
  }

  Future<T> run<T>(
    String key,
    Future<T> Function() action, {
    AiRequestKind kind = AiRequestKind.chat,
    String fingerprint = '',
    T Function()? limited,
    bool Function(T value)? succeeded,
  }) {
    final existing = _inflight[key];
    if (existing != null) {
      return existing.then((value) => value as T);
    }
    if (_blocked(kind, fingerprint)) {
      return Future<T>.value(_limited(limited));
    }
    _noteBurst(kind);
    final created = action();
    _inflight[key] = created;
    created.then((value) {
      if (fingerprint.isEmpty) return;
      if (succeeded != null && !succeeded(value)) return;
      _lastOk[fingerprint] = DateTime.now();
    }).catchError((_) {});
    created.whenComplete(() => _inflight.remove(key));
    return created;
  }

  Future<AiOutcome<T>> runOutcome<T>(
    String key,
    Future<AiOutcome<T>> Function() action, {
    required AiRequestKind kind,
    String fingerprint = '',
  }) {
    return run(
      key,
      action,
      kind: kind,
      fingerprint: fingerprint,
      limited: () => AiOutcome.failure(AiFailure.rateLimit()),
      succeeded: (o) => o.isSuccess,
    );
  }

  bool _blocked(AiRequestKind kind, String fingerprint) {
    final limits = AiRequestAbusePolicy.of(kind);
    if (fingerprint.isNotEmpty) {
      final last = _lastOk[fingerprint];
      if (last != null && DateTime.now().difference(last) < limits.duplicate) {
        return true;
      }
    }
    final hits = _recent(kind, limits.burstWindow);
    return hits.length >= limits.burstMax;
  }

  void _noteBurst(AiRequestKind kind) {
    final limits = AiRequestAbusePolicy.of(kind);
    final next = [..._recent(kind, limits.burstWindow), DateTime.now()];
    _burst[kind] = next;
  }

  List<DateTime> _recent(AiRequestKind kind, Duration window) {
    final now = DateTime.now();
    return [
      for (final at in _burst[kind] ?? const <DateTime>[])
        if (now.difference(at) < window) at,
    ];
  }

  T _limited<T>(T Function()? limited) {
    if (limited != null) return limited();
    throw StateError('ai_request_limited');
  }

  @visibleForTesting
  void reset() {
    _inflight.clear();
    _lastOk.clear();
    _burst.clear();
  }
}
