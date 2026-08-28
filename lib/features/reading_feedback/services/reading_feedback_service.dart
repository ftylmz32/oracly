/// Records feedback and optional free retry — never spends gems.
library;

import '../../../core/quality/quality_signal_recorder.dart';
import '../data/reading_feedback_store.dart';
import '../models/reading_feedback_category.dart';
import '../models/reading_feedback_event.dart';

class ReadingFeedbackService {
  ReadingFeedbackService(this._store, {this.quality});

  final ReadingFeedbackStore _store;
  final QualitySignalRecorder? quality;

  Future<void> record({
    required QualityFeature feature,
    required QualityIssue category,
    required bool ok,
    DateTime? at,
  }) async {
    await _store.add(
      ReadingFeedbackEvent(
        feature: feature,
        category: category,
        ok: ok,
        at: at ?? DateTime.now(),
      ),
    );
    await quality?.negative(feature, category);
  }

  Future<bool> retryWithoutCharge({
    required QualityFeature feature,
    required QualityIssue category,
    required Future<bool> Function() retry,
  }) async {
    await quality?.negative(feature, category);
    await quality?.retry(feature);
    try {
      final changed = await retry();
      await _store.add(
        ReadingFeedbackEvent(
          feature: feature,
          category: category,
          ok: true,
          at: DateTime.now(),
        ),
      );
      return changed;
    } catch (_) {
      await _store.add(
        ReadingFeedbackEvent(
          feature: feature,
          category: category,
          ok: false,
          at: DateTime.now(),
        ),
      );
      rethrow;
    }
  }
}
