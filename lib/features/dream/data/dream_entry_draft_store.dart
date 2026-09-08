/// Local draft persistence for the Dream entry flow.
library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';
import '../models/dream_entry_context.dart';

class DreamEntryDraft {
  const DreamEntryDraft({
    required this.narrative,
    required this.chips,
    required this.guidedAnswers,
  });

  final String narrative;
  final Set<DreamEntryChipId> chips;
  final Map<DreamGuidedQuestionId, String> guidedAnswers;

  bool get isEmpty =>
      narrative.trim().isEmpty && chips.isEmpty &&
      guidedAnswers.values.every((value) => value.trim().isEmpty);
}

/// Keeps unfinished Dream input safe across navigation and app restarts.
class DreamEntryDraftStore {
  DreamEntryDraftStore(this._storage);

  final LocalStorage _storage;

  static const _narrativeKey = 'dream.entry_draft.narrative.v1';
  static const _chipsKey = 'dream.entry_draft.chips.v1';
  static const _guidedKey = 'dream.entry_draft.guided.v1';

  DreamEntryDraft? load() {
    final narrative = _storage.getString(_narrativeKey) ?? '';
    final chipNames = _storage.getStringList(_chipsKey) ?? const <String>[];
    final guidedRaw = _storage.getString(_guidedKey);

    final chips = <DreamEntryChipId>{};
    for (final name in chipNames) {
      for (final id in DreamEntryChipId.values) {
        if (id.name == name) chips.add(id);
      }
    }

    final guided = <DreamGuidedQuestionId, String>{};
    if (guidedRaw != null && guidedRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(guidedRaw);
        if (decoded is Map<String, dynamic>) {
          for (final id in DreamGuidedQuestionId.values) {
            final value = decoded[id.name];
            if (value is String && value.trim().isNotEmpty) {
              guided[id] = value;
            }
          }
        }
      } catch (_) {
        // Corrupt/old drafts are best-effort only; never block Dream entry.
      }
    }

    final draft = DreamEntryDraft(
      narrative: narrative,
      chips: chips,
      guidedAnswers: guided,
    );
    return draft.isEmpty ? null : draft;
  }

  Future<void> save({
    required String narrative,
    required Set<DreamEntryChipId> chips,
    required Map<DreamGuidedQuestionId, String> guidedAnswers,
  }) async {
    final cleanGuided = <String, String>{
      for (final entry in guidedAnswers.entries)
        if (entry.value.trim().isNotEmpty) entry.key.name: entry.value,
    };

    await _storage.setString(_narrativeKey, narrative);
    await _storage.setStringList(
      _chipsKey,
      chips.map((id) => id.name).toList(growable: false),
    );
    await _storage.setString(_guidedKey, jsonEncode(cleanGuided));
  }

  Future<void> clear() async {
    await _storage.remove(_narrativeKey);
    await _storage.remove(_chipsKey);
    await _storage.remove(_guidedKey);
  }
}
