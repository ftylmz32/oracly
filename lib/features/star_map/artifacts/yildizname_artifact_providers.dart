/// Riverpod providers for owner-safe Yıldızname artifacts.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/user_local_data_isolation.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/providers/backend_providers.dart';
import 'local_yildizname_artifact_repository.dart';
import 'yildizname_artifact.dart';
import 'yildizname_artifact_exceptions.dart';
import 'yildizname_artifact_repository.dart';
import 'yildizname_artifact_source.dart';
import 'yildizname_legacy_capture_service.dart';
import 'yildizname_narrative_completion_service.dart';

final yildiznameArtifactRepositoryProvider =
    Provider<YildiznameArtifactRepository>((ref) {
  ref.watch(localDataOwnerEpochProvider);
  final storage = ref.watch(localStorageProvider);
  final ownerId = storage.getString(UserLocalDataIsolation.ownerKey);
  return LocalYildiznameArtifactRepository(storage, ownerId: ownerId);
});

final yildiznameArtifactHistoryProvider =
    FutureProvider<List<YildiznameArtifact>>((ref) async {
  ref.watch(localDataOwnerEpochProvider);
  final repo = ref.watch(yildiznameArtifactRepositoryProvider);
  try {
    return await repo.getAll();
  } on YildiznameArtifactOwnerUnavailableException {
    return const [];
  }
});

final yildiznameArtifactByIdProvider =
    FutureProvider.family<YildiznameArtifact?, String>((ref, id) async {
  ref.watch(localDataOwnerEpochProvider);
  final repo = ref.watch(yildiznameArtifactRepositoryProvider);
  try {
    return await repo.getById(id);
  } on YildiznameArtifactOwnerUnavailableException {
    return null;
  }
});

final yildiznameNarrativeCompletionServiceProvider =
    Provider<YildiznameNarrativeCompletionService>((ref) {
  return YildiznameNarrativeCompletionService(
    ref.watch(yildiznameArtifactRepositoryProvider),
  );
});

final yildiznameLegacyCaptureServiceProvider =
    Provider<YildiznameLegacyCaptureService>((ref) {
  return YildiznameLegacyCaptureService(
    ref.watch(yildiznameArtifactRepositoryProvider),
  );
});

/// Newest owner-safe Narrative V1 reading for exactly this chart evidence and
/// language: summary + closing prose only (no refs). Null when none matches,
/// so the hub never shows a reading made for different birth data.
final yildiznameHubNarrativeProvider =
    FutureProvider.family<String?, String>((ref, evidenceFingerprint) async {
  final history = await ref.watch(yildiznameArtifactHistoryProvider.future);
  final lang = OraclyL10n.code;
  final matches = history
      .where((a) =>
          a.source == YildiznameArtifactSource.narrativeV1 &&
          a.evidenceFingerprint == evidenceFingerprint &&
          (a.resultLocale == null || a.resultLocale == lang))
      .toList()
    ..sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
  for (final a in matches) {
    final result = a.payload['result'];
    if (result is! Map) continue;
    final summary = result['summary'];
    final text = summary is Map ? (summary['text'] as String? ?? '').trim() : '';
    if (text.isEmpty) continue;
    final closing = (result['closingMessage'] as String? ?? '').trim();
    return closing.isEmpty ? text : '$text\n\n$closing';
  }
  return null;
});
