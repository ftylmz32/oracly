/// Personal memory core — compact, private, event-gated.
library;

import '../../../features/personal_discovery/models/personal_discovery_profile.dart';
import '../data/personal_memory_store.dart';
import '../domain/models/personal_memory_summary.dart';
import 'personal_memory_builder.dart';
import 'personal_memory_or_copy.dart';

class PersonalMemoryService {
  PersonalMemoryService(this._store);

  final PersonalMemoryStore _store;

  PersonalMemorySummary load() => _store.load();

  Future<void> clear() => _store.clear();

  Future<void> userReset() => _store.userReset();

  /// Rebuilds from profile; writes only when the compact fingerprint changes.
  Future<PersonalMemorySummary> reconcile(
    PersonalDiscoveryProfile profile, {
    String? preferredName,
    DateTime? now,
  }) async {
    final next = PersonalMemoryBuilder.fromProfile(
      profile,
      preferredName: preferredName,
      now: now,
    );
    final blocked = _store.blockedFingerprint();
    if (blocked != null) {
      if (next.fingerprint == blocked) {
        return PersonalMemorySummary.empty;
      }
      await _store.clearResetBlock();
    }
    final previous = _store.load();
    if (!PersonalMemoryBuilder.changed(previous, next)) {
      return previous;
    }
    if (next.isEmpty) {
      await _store.clear();
      return PersonalMemorySummary.empty;
    }
    await _store.save(next);
    return next;
  }

  String? observationalLine({String lang = 'tr'}) {
    final summary = _store.load();
    return PersonalMemoryOrCopy.tension(summary, lang: lang) ??
        PersonalMemoryOrCopy.observe(summary, lang: lang);
  }

  String? promptHint() => PersonalMemoryOrCopy.instruction(_store.load());
}
