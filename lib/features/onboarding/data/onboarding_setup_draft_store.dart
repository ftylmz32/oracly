library;

import 'dart:convert';

import '../../../core/data/datasources/local_storage.dart';
import 'onboarding_setup_draft.dart';

/// Local persistence for unfinished onboarding setup.
class OnboardingSetupDraftStore {
  const OnboardingSetupDraftStore(this._storage);

  final LocalStorage _storage;

  static const draftKey = 'onboarding_setup_draft';

  OnboardingSetupDraft? load() {
    final raw = _storage.getString(draftKey);
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      return OnboardingSetupDraft.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> save(OnboardingSetupDraft draft) async {
    await _storage.setString(draftKey, jsonEncode(draft.toJson()));
  }

  Future<void> clear() async {
    await _storage.remove(draftKey);
  }
}
