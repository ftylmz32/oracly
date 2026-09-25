/// Riverpod providers for owner-safe Yıldızname artifacts.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/user_local_data_isolation.dart';
import '../../../core/providers/backend_providers.dart';
import 'local_yildizname_artifact_repository.dart';
import 'yildizname_artifact.dart';
import 'yildizname_artifact_exceptions.dart';
import 'yildizname_artifact_repository.dart';
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
