/// One quality event — metadata only.
library;

import 'quality_feature.dart';
import 'quality_issue.dart';
import 'quality_signal_kind.dart';

class QualitySignalEvent {
  const QualitySignalEvent({
    required this.feature,
    required this.kind,
    required this.at,
    this.issue,
  });

  final QualityFeature feature;
  final QualitySignalKind kind;
  final DateTime at;
  final QualityIssue? issue;

  static const allowedKeys = {'feature', 'kind', 'at', 'issue'};

  Map<String, dynamic> toJson() => {
        'feature': feature.wire,
        'kind': kind.wire,
        'at': at.toIso8601String(),
        if (issue != null) 'issue': issue!.wire,
      };

  factory QualitySignalEvent.fromJson(Map<String, dynamic> json) {
    return QualitySignalEvent(
      feature: QualityFeature.fromWire('${json['feature']}') ??
          QualityFeature.tarot,
      kind: QualitySignalKind.fromWire('${json['kind']}') ??
          QualitySignalKind.started,
      at: DateTime.tryParse('${json['at']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      issue: QualityIssue.fromWire(json['issue'] as String?),
    );
  }
}
