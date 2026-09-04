/// Resolves the review-access service and its local cache repository.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/app_providers.dart';
import '../../../core/data/repositories/review_access_repository.dart';
import '../services/review_access_config.dart';
import '../services/review_access_service.dart';

final reviewAccessRepositoryProvider = Provider<ReviewAccessRepository>((ref) {
  return ReviewAccessRepository(
    ref.watch(localStorageProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

final reviewAccessServiceProvider = Provider<ReviewAccessService>((ref) {
  final url = ReviewAccessConfig.resolveActivateUrl();
  final tokenManager = ref.watch(tokenManagerProvider);
  return HttpReviewAccessService(
    activateUrl: url,
    accessTokenProvider: tokenManager.getAccessToken,
  );
});
