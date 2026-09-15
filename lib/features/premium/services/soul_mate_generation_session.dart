/// One logical Soulmate generation — owner-scoped, not a second portrait store.
library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';
import 'soul_mate_generation_policy.dart';

class SoulMateGenerationRecord {
  const SoulMateGenerationRecord({
    required this.ownerId,
    required this.logicalId,
    required this.fingerprint,
    required this.phase,
    this.name = '',
    this.birthIso = '',
    this.gender,
    this.intention,
  });

  final String ownerId;
  final String logicalId;
  final String fingerprint;
  final SoulMateGenerationPhase phase;
  final String name;
  final String birthIso;
  final String? gender;
  final String? intention;

  Map<String, dynamic> toJson() => {
        'ownerId': ownerId,
        'logicalId': logicalId,
        'fingerprint': fingerprint,
        'phase': phase.name,
        'name': name,
        'birthIso': birthIso,
        if (gender != null) 'gender': gender,
        if (intention != null) 'intention': intention,
      };

  static SoulMateGenerationRecord? fromJson(Map<String, dynamic> json) {
    final owner = json['ownerId'] as String? ?? '';
    final id = json['logicalId'] as String? ?? '';
    if (owner.isEmpty || id.isEmpty) return null;
    final phase = SoulMateGenerationPhase.values.firstWhere(
      (p) => p.name == json['phase'],
      orElse: () => SoulMateGenerationPhase.idle,
    );
    return SoulMateGenerationRecord(
      ownerId: owner,
      logicalId: id,
      fingerprint: json['fingerprint'] as String? ?? '',
      phase: phase,
      name: json['name'] as String? ?? '',
      birthIso: json['birthIso'] as String? ?? '',
      gender: json['gender'] as String?,
      intention: json['intention'] as String?,
    );
  }
}

abstract final class SoulMateGenerationSessionStore {
  SoulMateGenerationSessionStore._();

  static const key = 'soulmate_generation_session';

  static SoulMateGenerationRecord? read(LocalStorage storage) {
    final raw = storage.getString(key);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return SoulMateGenerationRecord.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(
    LocalStorage storage,
    SoulMateGenerationRecord record,
  ) {
    return storage.setString(key, jsonEncode(record.toJson()));
  }

  static Future<void> clear(LocalStorage storage) => storage.remove(key);

  /// Drop another account's in-flight marker. Does not touch a saved portrait.
  static Future<SoulMateGenerationRecord?> readForOwner(
    LocalStorage storage,
    String ownerId,
  ) async {
    final current = read(storage);
    if (current == null) return null;
    if (current.ownerId != ownerId) {
      await clear(storage);
      return null;
    }
    return current;
  }
}
