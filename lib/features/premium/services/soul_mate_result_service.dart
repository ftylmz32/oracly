/// Orchestrates Soulmate flagship save + revisit.
library;

import 'dart:io';

import '../../../core/data/datasources/local_storage.dart';
import '../../../core/l10n/l10n.dart';
import '../data/soul_mate_interpretation_catalogue.dart';
import '../data/soul_mate_result_store.dart';
import '../models/soul_mate_saved_result.dart';
import '../services/soul_mate_draw_port.dart';
import '../services/soul_mate_interpretation.dart';

class SoulMateResultService {
  SoulMateResultService(this._storage);

  final LocalStorage _storage;

  Future<SoulMateSavedResult?> latestMeta() => SoulMateResultStore.readMeta(_storage);

  Future<({SoulMateSavedResult meta, List<int> bytes})?> latestWithPortrait() async {
    final meta = await latestMeta();
    if (meta == null) return null;
    final bytes = await SoulMateResultStore.readPortraitBytes(meta.portraitPath);
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
  }) async {
    if (imageBytes.isEmpty) return null;
    final resolved = parts ??
        SoulMateInterpretation.partsFor(request);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
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
    );
    return SoulMateResultStore.save(
      storage: _storage,
      record: draft,
      portraitBytes: imageBytes,
      documents: documents,
    );
  }

  Future<void> clear() => SoulMateResultStore.clear(_storage);
}