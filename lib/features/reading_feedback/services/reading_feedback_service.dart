/// Records feedback and optional free retry — never spends gems.
library;

import '../../../core/quality/quality_signal_recorder.dart';
import '../data/reading_feedback_store.dart';
import '../models/reading_feedback_category.dart';
import '../models/reading_feedback_event.dart';
import 'content_report_gateway.dart';

class ReadingFeedbackService {
  ReadingFeedbackService(this._store, {this.quality, this.delivery});

  final ReadingFeedbackStore _store;
  final QualitySignalRecorder? quality;
  final ContentReportGateway? delivery;

  String createReportId() {
    final gateway = delivery;
    if (gateway == null) {
      throw const ContentReportDeliveryException(
        ContentReportFailure.unavailable,
      );
    }
    return gateway.createReportId();
  }

  Future<void> record({
    required QualityFeature feature,
    required QualityIssue category,
    required bool ok,
    required String reportId,
    DateTime? at,
    String? contentRef,
    String? selectedContent,
  }) async {
    final gateway = delivery;
    if (gateway == null) {
      throw const ContentReportDeliveryException(
        ContentReportFailure.unavailable,
      );
    }
    await gateway.submit(
      reportId: reportId,
      feature: feature,
      category: category,
      contentRef: contentRef,
      selectedContent: selectedContent,
    );
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
