/// Authenticated, metadata-only AI content report delivery.
library;

// `send` is intentionally public while the stored callback remains private.
// ignore_for_file: prefer_initializing_formals

import 'dart:async';
import 'dart:math';

import '../../reading_operation/services/reading_operation_gateway.dart';
import '../models/reading_feedback_category.dart';

enum ContentReportFailure { unavailable, rejected, timeout, invalidResponse }

class ContentReportDeliveryException implements Exception {
  const ContentReportDeliveryException(this.failure);
  final ContentReportFailure failure;
}

typedef ContentReportIdFactory = String Function();

class ContentReportGateway {
  ContentReportGateway({
    required ReadingOperationSender send,
    this.timeout = const Duration(seconds: 12),
    ContentReportIdFactory? createReportId,
  }) : _send = send,
       _createReportId = createReportId ?? _defaultReportId;

  final ReadingOperationSender _send;
  final Duration timeout;
  final ContentReportIdFactory _createReportId;

  String createReportId() => _createReportId();

  Future<String> submit({
    required String reportId,
    required QualityFeature feature,
    required QualityIssue category,
    String? contentRef,
    String? selectedContent,
  }) async {
    final content = selectedContent?.trim();
    final body = <String, Object>{
      'reportId': reportId,
      'feature': feature.wire,
      'category': category.wire,
      if (contentRef != null && contentRef.trim().isNotEmpty)
        'contentRef': contentRef.trim(),
      if (content != null && content.isNotEmpty) ...{
        'selectedContent': content.length > 2000
            ? content.substring(0, 2000)
            : content,
        'contentConsent': true,
      },
    };
    ContentReportDeliveryException? lastFailure;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final wire = await _send(
          'POST',
          '/v1/content-reports',
          body,
        ).timeout(timeout);
        if (wire == null) {
          lastFailure = const ContentReportDeliveryException(
            ContentReportFailure.unavailable,
          );
          continue;
        }
        if (wire.statusCode < 200 || wire.statusCode >= 300) {
          if (wire.statusCode >= 500 && attempt == 0) {
            lastFailure = const ContentReportDeliveryException(
              ContentReportFailure.rejected,
            );
            continue;
          }
          throw const ContentReportDeliveryException(
            ContentReportFailure.rejected,
          );
        }
        final data = wire.json?['data'];
        if (data is Map &&
            data['accepted'] == true &&
            data['reportId'] == reportId) {
          return reportId;
        }
        throw const ContentReportDeliveryException(
          ContentReportFailure.invalidResponse,
        );
      } on TimeoutException {
        lastFailure = const ContentReportDeliveryException(
          ContentReportFailure.timeout,
        );
      }
    }
    throw lastFailure ??
        const ContentReportDeliveryException(ContentReportFailure.unavailable);
  }

  static String _defaultReportId() {
    final random = Random.secure();
    final entropy = List<int>.generate(
      16,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return 'report_$entropy';
  }
}
