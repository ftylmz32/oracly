/// One in-flight Soulmate generation. Rapid taps join it; they do not fork it.
library;

import '../../../core/data/datasources/local_storage.dart';
import 'soul_mate_draw_port.dart';
import 'soul_mate_generation_identity.dart';
import 'soul_mate_generation_policy.dart';
import 'soul_mate_generation_session.dart';

class SoulMateGenerationRunner {
  Future<SoulMateDrawResult>? _inflight;
  String? _owner;

  bool isInFlightFor(String ownerId) =>
      _inflight != null && _owner == ownerId;

  Future<SoulMateDrawResult>? currentFor(String ownerId) =>
      isInFlightFor(ownerId) ? _inflight : null;

  /// [fresh] only applies after the previous generation has finished.
  Future<SoulMateDrawResult> start({
    required LocalStorage storage,
    required String ownerId,
    required String fingerprint,
    required bool fresh,
    required String name,
    required String birthIso,
    String? gender,
    String? intention,
    required Future<SoulMateDrawResult> Function(String logicalId) drawOnce,
    DateTime Function()? now,
  }) {
    if (isInFlightFor(ownerId)) return _inflight!;
    final future = _execute(
      storage: storage,
      ownerId: ownerId,
      fingerprint: fingerprint,
      fresh: fresh,
      name: name,
      birthIso: birthIso,
      gender: gender,
      intention: intention,
      drawOnce: drawOnce,
      now: now ?? DateTime.now,
    );
    _inflight = future;
    _owner = ownerId;
    future.whenComplete(() {
      if (identical(_inflight, future)) {
        _inflight = null;
        _owner = null;
      }
    });
    return future;
  }

  Future<SoulMateDrawResult> _execute({
    required LocalStorage storage,
    required String ownerId,
    required String fingerprint,
    required bool fresh,
    required String name,
    required String birthIso,
    String? gender,
    String? intention,
    required Future<SoulMateDrawResult> Function(String logicalId) drawOnce,
    required DateTime Function() now,
  }) async {
    final logicalId = await SoulMateGenerationIdentity.resolve(
      storage: storage,
      ownerId: ownerId,
      fingerprint: fingerprint,
      fresh: fresh,
    );
    Future<void> mark(SoulMateGenerationPhase phase) {
      return SoulMateGenerationIdentity.write(
        storage,
        ownerId: ownerId,
        logicalId: logicalId,
        fingerprint: fingerprint,
        phase: phase,
        name: name,
        birthIso: birthIso,
        gender: gender,
        intention: intention,
      );
    }

    await mark(SoulMateGenerationPhase.submitting);
    var last = const SoulMateDrawResult.unavailable('');
    for (var attempt = 1;
        attempt <= SoulMateGenerationPolicy.maxAttempts;
        attempt++) {
      final started = now();
      last = await drawOnce(logicalId);
      if (last.declined) {
        await SoulMateGenerationSessionStore.clear(storage);
        return last.tagged(logicalId);
      }
      if (last.hasPortrait) {
        await mark(SoulMateGenerationPhase.succeeded);
        return last.tagged(logicalId);
      }
      final kind = last.aiKind;
      final retry = kind != null &&
          SoulMateGenerationPolicy.shouldAutoRetry(
            kind: kind,
            completedAttempts: attempt,
            elapsed: now().difference(started),
          );
      if (!retry) break;
      await mark(SoulMateGenerationPhase.generating);
    }
    final failure = last.failureKind ??
        (last.aiKind == null
            ? SoulMateFailureKind.temporary
            : SoulMateGenerationPolicy.failureKindFor(last.aiKind!));
    await mark(
      failure == SoulMateFailureKind.unavailable
          ? SoulMateGenerationPhase.failedFinal
          : SoulMateGenerationPhase.failedRecoverable,
    );
    return last.tagged(logicalId, failureKind: last.failureKind ?? failure);
  }
}
