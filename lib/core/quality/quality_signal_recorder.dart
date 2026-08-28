/// Records funnel and opinion signals; tracks open sessions for abandon.
library;

import 'quality_feature.dart';
import 'quality_issue.dart';
import 'quality_signal_event.dart';
import 'quality_signal_kind.dart';
import 'quality_signal_store.dart';

class QualitySignalRecorder {
  QualitySignalRecorder(this._store);

  final QualitySignalStore _store;
  final Set<QualityFeature> _open = {};

  bool isOpen(QualityFeature feature) => _open.contains(feature);

  Future<void> started(QualityFeature feature) {
    _open.add(feature);
    return _write(feature, QualitySignalKind.started);
  }

  Future<void> completed(QualityFeature feature) {
    _open.remove(feature);
    return _write(feature, QualitySignalKind.completed);
  }

  Future<void> abandonedIfOpen(QualityFeature feature) {
    if (!_open.remove(feature)) return Future.value();
    return _write(feature, QualitySignalKind.abandoned);
  }

  Future<void> positive(QualityFeature feature) =>
      _write(feature, QualitySignalKind.positive);

  Future<void> negative(QualityFeature feature, QualityIssue issue) =>
      _write(feature, QualitySignalKind.negative, issue: issue);

  Future<void> retry(QualityFeature feature) =>
      _write(feature, QualitySignalKind.retry);

  Future<void> _write(
    QualityFeature feature,
    QualitySignalKind kind, {
    QualityIssue? issue,
  }) {
    return _store.add(
      QualitySignalEvent(
        feature: feature,
        kind: kind,
        issue: issue,
        at: DateTime.now(),
      ),
    );
  }
}
