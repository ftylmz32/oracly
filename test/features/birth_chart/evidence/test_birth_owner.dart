/// Test helper — owner-bound birth chart repository.
library;

import 'package:oracly_new/core/auth/user_local_data_isolation.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/data/repositories/local_birth_chart_repository.dart';

const kTestBirthOwnerA = 'test-owner-a';
const kTestBirthOwnerB = 'test-owner-b';

LocalBirthChartRepository testBirthChartRepo(
  LocalStorage storage, {
  String? ownerId = kTestBirthOwnerA,
  bool seedOwnerKey = true,
}) {
  if (seedOwnerKey && ownerId != null && ownerId.trim().isNotEmpty) {
    storage.setString(UserLocalDataIsolation.ownerKey, ownerId);
  }
  return LocalBirthChartRepository(storage, ownerId: ownerId);
}

/// Harness repo that does not force-seed ownerKey (tests that call setOwner).
LocalBirthChartRepository testBirthChartRepoPassive(
  LocalStorage storage, {
  String? ownerId,
}) {
  return LocalBirthChartRepository(storage, ownerId: ownerId);
}
