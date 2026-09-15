/// Orchestrates Soulmate flagship save + revisit.
library;

import 'dart:convert';
import 'dart:io';

import '../../../core/auth/user_local_data_isolation.dart';
import '../../../core/data/datasources/local_storage.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/memory/oracly_memory_factory.dart';
import '../../../core/memory/oracly_memory_store.dart';
import '../data/soul_mate_interpretation_catalogue.dart';
import '../data/soul_mate_result_store.dart';
import '../models/soul_mate_saved_result.dart';
import '../services/soul_mate_draw_port.dart';
import '../services/soul_mate_identity.dart';
import '../services/soul_mate_portrait_guard.dart';

class SoulMateResultService {
  SoulMateResultService(this._storage, {this._memory});

  final LocalStorage _storage;
  final OraclyMemoryStore? _memory;

  Future<SoulMateSavedResult?> latestMeta() =>
      SoulMateResultStore.readMeta(_storage);

  Future<({SoulMateSavedResult meta, List<int> bytes})?>
  latestWithPortrait() async {
    final meta = await latestMeta();
    if (meta == null) return null;
    final bytes = await SoulMateResultStore.readPortraitBytes(
      meta.portraitPath,
    );
    if (bytes == null || bytes.isEmpty) return null;
    return (meta: meta, bytes: bytes);
  }

  Future<bool> hasSavedResult() async {
    final loaded = await latestWithPortrait();
    return loaded != null;
  }

  Future<SoulMateSavedResult?> saveSuccessfulDraw({
    required SoulMateDrawRequest request,
    required List<int> imageBytes,
    SoulMateReadingParts? parts,
    Directory? documents,
    String? recordId,
    String? expectedOwnerId,
    SoulMateIdentity? identity,
  }) async {
    if (imageBytes.isEmpty) return null;
    if (expectedOwnerId != null) {
      final current = _storage.getString(UserLocalDataIsolation.ownerKey);
      if (current != null && current != expectedOwnerId) return null;
    }
    final hash = identity?.contentHash ?? '';
    if (expectedOwnerId != null &&
        !const SoulMatePortraitGuard().accepts(
          contentHash: hash,
          ownerId: expectedOwnerId,
          knownOwners: _knownHashes(),
        )) {
      return null;
    }
    final previous = await latestMeta();
    final id = _stableId(recordId);
    final keepPriorText =
        parts?.authoritative != true &&
        previous != null &&
        previous.id == id &&
        previous.hasAuthoritativeInterpretation;
    final resolved = keepPriorText
        ? previous.parts
        : (parts ??
              const SoulMateReadingParts(
                energy: '',
                attraction: '',
                dynamics: '',
                feeling: '',
                yourSide: '',
              ));
    final draft = SoulMateSavedResult(
      id: id,
      createdAt: DateTime.now(),
      name: request.name.trim(),
      birthDate: request.birthDate,
      gender: request.gender,
      intention: request.intention,
      portraitPath: '',
      parts: resolved,
      localeCode: OraclyL10n.code,
      identity: identity ?? (previous?.id == id ? previous?.identity : null),
    );
    final saved = await SoulMateResultStore.save(
      storage: _storage,
      record: draft,
      portraitBytes: imageBytes,
      documents: documents,
    );
    if (saved != null && hash.isNotEmpty && expectedOwnerId != null) {
      final known = _knownHashes();
      known[hash] = expectedOwnerId;
      await _storage.setString(_hashKey, hashOwnersToJson(known));
    }
    final savedIdentity = saved?.identity;
    if (savedIdentity != null && savedIdentity.faceShape.isNotEmpty) {
      await _storage.setString(
        'soulmate_portrait_identity',
        jsonEncode({
          'version': savedIdentity.version,
          'presence': savedIdentity.presence,
          'ageBand': savedIdentity.ageBand,
          'faceShape': savedIdentity.faceShape,
          'hairFamily': savedIdentity.hairFamily,
          'relationshipArchetype': savedIdentity.relationshipArchetype,
        }),
      );
    }
    if (saved != null && saved.hasAuthoritativeInterpretation) {
      try {
        await _memory?.upsert(OraclyMemoryFactory.soulmate(saved));
      } catch (_) {
        // The saved portrait/result remains authoritative without the index.
      }
    }
    return saved;
  }

  Future<void> clear() async {
    final prior = await latestMeta();
    await SoulMateResultStore.clear(_storage);
    await _storage.remove('soulmate_portrait_hashes');
    await _storage.remove('soulmate_portrait_identity');
    if (prior != null) {
      try {
        await _memory?.removeBySource(prior.id);
      } catch (_) {
        // Clearing the source must not depend on connected memory health.
      }
    }
  }

  static const _hashKey = 'soulmate_portrait_hashes';

  Map<String, String> _knownHashes() {
    final raw = _storage.getString(_hashKey);
    if (raw == null || raw.trim().isEmpty) return {};
    return hashOwnersFromJson(raw);
  }

  static String _stableId(String? recordId) {
    final raw = recordId?.trim() ?? '';
    final safe = raw.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '');
    if (safe.isEmpty) return DateTime.now().millisecondsSinceEpoch.toString();
    return safe.length <= 80 ? safe : safe.substring(0, 80);
  }
}
