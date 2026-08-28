/// Reading feedback Riverpod wiring.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/backend_providers.dart';
import '../../quality_loop/providers/quality_loop_providers.dart';
import '../data/reading_feedback_store.dart';
import '../services/reading_feedback_service.dart';

final readingFeedbackStoreProvider = Provider<ReadingFeedbackStore>((ref) {
  return ReadingFeedbackStore(ref.watch(localStorageProvider));
});

final readingFeedbackServiceProvider = Provider<ReadingFeedbackService>((ref) {
  return ReadingFeedbackService(
    ref.watch(readingFeedbackStoreProvider),
    quality: ref.watch(qualitySignalRecorderProvider),
  );
});
