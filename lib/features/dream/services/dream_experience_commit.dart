/// Owner-checked Dream persistence — record, memory, and version together.
library;

import '../../../core/domain/repositories/dream_repository.dart';
import '../../../core/reading_version/models/reading_version_kind.dart';
import '../../../core/reading_version/services/reading_version_payload.dart';
import '../../../core/reading_version/services/reading_version_service.dart';
import '../data/dream_record_mapper.dart';
import '../models/dream.dart';
import 'dream_owner_guard.dart';

class DreamExperienceResult {
  const DreamExperienceResult({required this.dream, this.versionAdded = true});

  final Dream dream;
  final bool versionAdded;
}

/// Policy:
/// 1. The owner snapshot is re-checked immediately before the first write,
///    so a completed switch/clear is refused before anything is written.
/// 2. A revision commits the Dream record only after the version chain
///    accepted it — a no-op or rejected revision never rewrites the record.
/// 3. After the last write the snapshot is checked again. On mismatch only
///    this operation's Dream id is reverted (record + its connected memory
///    via [DreamRepository.delete], and its version root) — ids are minted
///    per operation, so no other owner's rows can match.
/// 4. A new Dream is written record-last: version root → owner check →
///    record (+ connected memory) → owner check. A failed or raced root
///    never lets the record be written, so no rollback is needed to keep a
///    failed Dream invisible. A failed record write deletes it and removes
///    the root best-effort; if that cleanup also fails, only a hidden
///    version root can remain — never a visible Dream record.
class DreamExperienceCommit {
  const DreamExperienceCommit({
    required this.repository,
    required this.owner,
    this._versions,
  });

  final DreamRepository repository;
  final DreamOwnerGuard owner;
  final ReadingVersionService? _versions;

  Future<DreamExperienceResult> commit({
    required Dream dream,
    required DreamOwnerSnapshot snapshot,
    required bool isRevision,
  }) async {
    if (!owner.stillValid(snapshot)) throw const DreamOwnerChangedException();
    final record = DreamRecordMapper.toRecord(dream);
    final payload = ReadingVersionPayload.dream(dream, record.analysis);
    final versions = _versions;

    if (isRevision && versions != null) {
      final result = await versions.tryAppendRevision(
        rootId: dream.id,
        kind: ReadingVersionKind.dream,
        data: payload,
      );
      if (!result.added) {
        final prior = await repository.getById(dream.id);
        if (!owner.stillValid(snapshot) || prior == null) {
          throw const DreamOwnerChangedException();
        }
        return DreamExperienceResult(
          dream: DreamRecordMapper.fromRecord(prior),
          versionAdded: false,
        );
      }
    }

    if (isRevision) {
      await repository.save(record);
    } else {
      if (versions != null) {
        try {
          await versions.seedOriginal(
            rootId: dream.id,
            kind: ReadingVersionKind.dream,
            data: payload,
          );
        } catch (_) {
          await _removeRoot(dream.id);
          rethrow;
        }
        if (!owner.stillValid(snapshot)) {
          await _removeRoot(dream.id);
          throw const DreamOwnerChangedException();
        }
      }
      try {
        await repository.save(record);
      } catch (_) {
        await _revert(dream.id);
        rethrow;
      }
    }

    if (!owner.stillValid(snapshot)) {
      await _revert(dream.id);
      throw const DreamOwnerChangedException();
    }
    return DreamExperienceResult(dream: dream);
  }

  Future<void> _revert(String id) async {
    try {
      await repository.delete(id);
    } catch (_) {}
    await _removeRoot(id);
  }

  Future<void> _removeRoot(String id) async {
    try {
      await _versions?.removeRoot(id);
    } catch (_) {}
  }
}
