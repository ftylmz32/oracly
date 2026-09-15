/// Stable Soulmate operation id ? reuse in-flight, never another user's.
library;

import '../../../core/data/datasources/local_storage.dart';
import '../../gems/services/paid_ai_operation_id.dart';
import 'soul_mate_generation_policy.dart';
import 'soul_mate_generation_session.dart';

abstract final class SoulMateGenerationIdentity {
  SoulMateGenerationIdentity._();

  static Future<String> resolve({
    required LocalStorage storage,
    required String ownerId,
    required String fingerprint,
    required bool fresh,
  }) async {
    if (!fresh) {
      final existing =
          await SoulMateGenerationSessionStore.readForOwner(storage, ownerId);
      if (existing != null &&
          existing.fingerprint == fingerprint &&
          existing.logicalId.isNotEmpty &&
          existing.phase != SoulMateGenerationPhase.succeeded) {
        return existing.logicalId;
      }
    }
    return PaidAiOperationId.create('soulmate');
  }

  static Future<void> write(
    LocalStorage storage, {
    required String ownerId,
    required String logicalId,
    required String fingerprint,
    required SoulMateGenerationPhase phase,
    required String name,
    required String birthIso,
    String? gender,
    String? intention,
  }) {
    return SoulMateGenerationSessionStore.write(
      storage,
      SoulMateGenerationRecord(
        ownerId: ownerId,
        logicalId: logicalId,
        fingerprint: fingerprint,
        phase: phase,
        name: name,
        birthIso: birthIso,
        gender: gender,
        intention: intention,
      ),
    );
  }
}
