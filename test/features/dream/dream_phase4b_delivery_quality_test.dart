// Dream Phase 4B — the centralized configured-AI completeness contract.
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/dream/models/dream_insight.dart';
import 'package:oracly_new/features/dream/services/dream_premium_delivery_quality.dart';

DreamInsight _section(
  DreamInsightKind kind, {
  DreamInsightSource source = DreamInsightSource.ai,
  String body = 'A grounded section about the red door on the beach.',
}) =>
    DreamInsight(kind: kind, title: kind.name, body: body, source: source);

List<DreamInsight> _complete() => [
      for (final kind in DreamPremiumDeliveryQuality.required) _section(kind),
      _section(DreamInsightKind.themes, source: DreamInsightSource.local),
    ];

void main() {
  test('requires four AI sections; optional life reflection may be absent', () {
    expect(DreamPremiumDeliveryQuality.required, [
      DreamInsightKind.summary,
      DreamInsightKind.emotionalMeaning,
      DreamInsightKind.mainInterpretation,
      DreamInsightKind.closingTakeaway,
    ]);
    expect(DreamPremiumDeliveryQuality.required,
        isNot(contains(DreamInsightKind.personalConnection)));
    expect(DreamPremiumDeliveryQuality.required,
        isNot(contains(DreamInsightKind.themes)));
    expect(DreamPremiumDeliveryQuality.required,
        isNot(contains(DreamInsightKind.recurringPattern)));
    expect(DreamPremiumDeliveryQuality.accepts(_complete()), isTrue);
  });

  test('absent reflection is valid, but a rejected local replacement is not', () {
    expect(DreamPremiumDeliveryQuality.accepts(_complete()), isTrue);
    final rejected = [
      ..._complete(),
      _section(DreamInsightKind.personalConnection,
          source: DreamInsightSource.local),
    ];
    expect(DreamPremiumDeliveryQuality.firstGap(
      rejected,
      reflectionExpected: true,
    ),
        DreamInsightKind.personalConnection);
  });

  for (final kind in DreamPremiumDeliveryQuality.required) {
    test('$kind missing, empty or local is the first gap', () {
      final missing = _complete()..removeWhere((i) => i.kind == kind);
      final empty = [
        for (final i in _complete())
          i.kind == kind ? _section(kind, body: '  ') : i,
      ];
      final local = [
        for (final i in _complete())
          i.kind == kind ? _section(kind, source: DreamInsightSource.local) : i,
      ];
      for (final insights in [missing, empty, local]) {
        expect(DreamPremiumDeliveryQuality.firstGap(insights), kind);
        expect(DreamPremiumDeliveryQuality.accepts(insights), isFalse);
      }
    });
  }
}
