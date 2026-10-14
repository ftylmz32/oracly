import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/quality/quality_feature.dart';
import 'package:oracly_new/core/quality/quality_issue.dart';
import 'package:oracly_new/features/reading_feedback/services/content_report_gateway.dart';
import 'package:oracly_new/features/reading_operation/services/reading_operation_gateway.dart';

void main() {
  const reportId = 'report_0123456789abcdef';

  test('accepts only matching backend acknowledgement', () async {
    Map<String, Object>? sent;
    final gateway = ContentReportGateway(
      createReportId: () => reportId,
      send: (method, path, body) async {
        sent = body;
        return const ReadingOperationWire(
          statusCode: 201,
          json: {
            'success': true,
            'data': {
              'accepted': true,
              'reportId': reportId,
              'duplicate': false,
            },
          },
        );
      },
    );

    expect(
      await gateway.submit(
        reportId: reportId,
        feature: QualityFeature.dream,
        category: QualityIssue.harmful,
      ),
      reportId,
    );
    expect(sent, {
      'reportId': reportId,
      'feature': 'dream',
      'category': 'harmful',
    });
    expect(sent!.containsKey('text'), isFalse);
    expect(sent!.containsKey('question'), isFalse);
    expect(sent!.containsKey('image'), isFalse);
  });

  test('network retry reuses one report id', () async {
    final ids = <Object?>[];
    var calls = 0;
    final gateway = ContentReportGateway(
      createReportId: () => reportId,
      send: (method, path, body) async {
        ids.add(body?['reportId']);
        calls++;
        if (calls == 1) return null;
        return const ReadingOperationWire(
          statusCode: 200,
          json: {
            'data': {'accepted': true, 'reportId': reportId, 'duplicate': true},
          },
        );
      },
    );

    await gateway.submit(
      reportId: reportId,
      feature: QualityFeature.companion,
      category: QualityIssue.inappropriate,
    );
    expect(ids, [reportId, reportId]);
  });

  test(
    'selected AI output is sent only when the caller supplies opt-in content',
    () async {
      final bodies = <Map<String, Object>>[];
      final gateway = ContentReportGateway(
        createReportId: () => reportId,
        send: (method, path, body) async {
          bodies.add(body!);
          return const ReadingOperationWire(
            statusCode: 201,
            json: {
              'data': {'accepted': true, 'reportId': reportId},
            },
          );
        },
      );
      await gateway.submit(
        reportId: reportId,
        feature: QualityFeature.companion,
        category: QualityIssue.harmful,
      );
      await gateway.submit(
        reportId: reportId,
        feature: QualityFeature.companion,
        category: QualityIssue.harmful,
        selectedContent: 'the selected assistant answer',
      );
      expect(bodies.first.containsKey('selectedContent'), isFalse);
      expect(bodies.first.containsKey('contentConsent'), isFalse);
      expect(bodies.last['selectedContent'], 'the selected assistant answer');
      expect(bodies.last['contentConsent'], isTrue);
      expect(bodies.last.containsKey('question'), isFalse);
      expect(bodies.last.containsKey('history'), isFalse);
      expect(bodies.last.containsKey('image'), isFalse);
    },
  );

  test('timeout fails without claiming delivery', () async {
    final gateway = ContentReportGateway(
      timeout: const Duration(milliseconds: 5),
      createReportId: () => reportId,
      send: (method, path, body) => Completer<ReadingOperationWire?>().future,
    );
    await expectLater(
      gateway.submit(
        reportId: reportId,
        feature: QualityFeature.tarot,
        category: QualityIssue.misleading,
      ),
      throwsA(
        isA<ContentReportDeliveryException>().having(
          (error) => error.failure,
          'failure',
          ContentReportFailure.timeout,
        ),
      ),
    );
  });

  test('server rejection fails without claiming delivery', () async {
    final gateway = ContentReportGateway(
      createReportId: () => reportId,
      send: (method, path, body) async => const ReadingOperationWire(
        statusCode: 403,
        json: {
          'error': {'code': 'forbidden'},
        },
      ),
    );
    await expectLater(
      gateway.submit(
        reportId: reportId,
        feature: QualityFeature.soulmate,
        category: QualityIssue.other,
      ),
      throwsA(isA<ContentReportDeliveryException>()),
    );
  });

  test('server error retries once and still fails closed', () async {
    var calls = 0;
    final gateway = ContentReportGateway(
      createReportId: () => reportId,
      send: (method, path, body) async {
        calls++;
        return const ReadingOperationWire(
          statusCode: 503,
          json: {
            'error': {'code': 'internal_error'},
          },
        );
      },
    );
    await expectLater(
      gateway.submit(
        reportId: reportId,
        feature: QualityFeature.coffee,
        category: QualityIssue.harmful,
      ),
      throwsA(isA<ContentReportDeliveryException>()),
    );
    expect(calls, 2);
  });
}
