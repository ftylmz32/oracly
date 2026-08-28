/// Quality loop — metadata signals, no private text, no model training.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/analytics/product_analytics_params.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/quality/quality_feature.dart';
import 'package:oracly_new/core/quality/quality_issue.dart';
import 'package:oracly_new/core/quality/quality_loop_privacy.dart';
import 'package:oracly_new/core/quality/quality_loop_reporter.dart';
import 'package:oracly_new/core/quality/quality_signal_event.dart';
import 'package:oracly_new/core/quality/quality_signal_kind.dart';
import 'package:oracly_new/core/quality/quality_signal_recorder.dart';
import 'package:oracly_new/core/quality/quality_signal_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('privacy forbids private text and model training', () {
    expect(QualityLoopPrivacy.storesRawContent, isFalse);
    expect(QualityLoopPrivacy.trainsFromUserContent, isFalse);
    expect(
      QualityLoopPrivacy.isSafe({
        'feature': 'tarot',
        'kind': 'negative',
        'at': '2026-08-20T00:00:00.000',
        'text': 'secret dream',
      }),
      isFalse,
    );
    expect(
      ProductAnalyticsParams.sanitize({
        'feature': 'coffee',
        'signal': 'negative',
        'issue': 'generic',
        'message': 'I dreamed of my mother',
      }),
      {'feature': 'coffee', 'signal': 'negative', 'issue': 'generic'},
    );
  });

  test('store drops unsafe payloads', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final store = QualitySignalStore(storage);
    await store.add(
      QualitySignalEvent(
        feature: QualityFeature.coffee,
        kind: QualitySignalKind.negative,
        issue: QualityIssue.generic,
        at: DateTime(2026, 8, 20),
      ),
    );
    final json = store.all().single.toJson();
    expect(json.keys.every(QualitySignalEvent.allowedKeys.contains), isTrue);
    expect(json.containsKey('text'), isFalse);
  });

  test('report names weakest, common issue, and strongest', () {
    final now = DateTime(2026, 8, 20);
    QualitySignalEvent e(
      QualityFeature feature,
      QualitySignalKind kind, {
      QualityIssue? issue,
    }) =>
        QualitySignalEvent(
          feature: feature,
          kind: kind,
          issue: issue,
          at: now,
        );
    final report = QualityLoopReporter.from([
      e(QualityFeature.coffee, QualitySignalKind.started),
      e(QualityFeature.coffee, QualitySignalKind.negative,
          issue: QualityIssue.generic),
      e(QualityFeature.coffee, QualitySignalKind.negative,
          issue: QualityIssue.generic),
      e(QualityFeature.coffee, QualitySignalKind.abandoned),
      e(QualityFeature.coffee, QualitySignalKind.retry),
      e(QualityFeature.tarot, QualitySignalKind.started),
      e(QualityFeature.tarot, QualitySignalKind.completed),
      e(QualityFeature.tarot, QualitySignalKind.positive),
      e(QualityFeature.tarot, QualitySignalKind.positive),
      e(QualityFeature.dream, QualitySignalKind.started),
      e(QualityFeature.dream, QualitySignalKind.negative,
          issue: QualityIssue.missed),
    ]);
    expect(report.problematic, QualityFeature.coffee);
    expect(report.commonIssue, QualityIssue.generic);
    expect(report.successful, QualityFeature.tarot);
  });

  test('abandon only fires when a session is open', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final recorder = QualitySignalRecorder(QualitySignalStore(storage));
    await recorder.abandonedIfOpen(QualityFeature.palm);
    expect(recorder.isOpen(QualityFeature.palm), isFalse);
    await recorder.started(QualityFeature.palm);
    await recorder.abandonedIfOpen(QualityFeature.palm);
    expect(
      QualitySignalStore(storage).all().map((e) => e.kind),
      containsAll([QualitySignalKind.started, QualitySignalKind.abandoned]),
    );
  });
}
