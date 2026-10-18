/// Hub portrait speaks only from the calculated chart and never invents.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/birth_chart/astronomy/evidence_aware_natal_calculator.dart';
import 'package:oracly_new/features/birth_chart/astronomy/natal_chart_evidence.dart';
import 'package:oracly_new/features/birth_chart/evidence/birth_timezone_status.dart';
import 'package:oracly_new/features/birth_chart/models/birth_profile.dart';
import 'package:oracly_new/features/star_map/services/star_map_chart_portrait.dart';

NatalChartEvidence _chart(DateTime date, {DateTime? time}) {
  return EvidenceAwareNatalChartCalculator()
      .calculate(
        BirthProfile(
          birthDate: date,
          birthPlace: 'İstanbul',
          birthTime: time,
          birthTimeKnown: time != null,
          latitude: 41.01,
          longitude: 28.98,
          timezoneId: 'Europe/Istanbul',
          timezoneResolutionStatus: BirthTimezoneStatus.resolved,
        ),
      )
      .natalEvidence!;
}

String _text(List<dynamic> sections) =>
    sections.map((s) => '${s.title} ${s.body}').join(' ');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  test('full chart: Sun, Moon, rising and a real aspect form one portrait', () {
    final sections = StarMapChartPortrait.build(
      _chart(DateTime(1985, 11, 3), time: DateTime(1985, 11, 3, 7, 15)),
    )!;
    final text = _text(sections);
    expect(text, contains('Güneşin Akrep burcunda'));
    expect(text, contains('Ay’ın Yengeç burcunda'));
    expect(text, contains('Yükselen burcun'));
    expect(text, contains(RegExp('üçgen|kare|sekstil|karşı karşıya|aynı noktada')));
    expect(sections.last.body, endsWith('?'));
  });

  test('without a birth time it never names a rising sign or houses', () {
    final sections =
        StarMapChartPortrait.build(_chart(DateTime(2001, 12, 30)))!;
    final text = _text(sections).toLowerCase();
    expect(text, contains('güneşin oğlak burcunda'));
    expect(text, isNot(contains('yükselen')));
    expect(text, isNot(contains('ev ')));
    expect(text, isNot(contains('haritanda ateş ağır')));
  });

  test('a weak element never contradicts the reader’s own big three', () {
    final sections = StarMapChartPortrait.build(
      _chart(DateTime(2002, 8, 1), time: DateTime(2002, 8, 1, 3, 5)),
    )!;
    // Rising Cancer is water: "too little water" would contradict the chart.
    expect(_text(sections), isNot(contains('Suyun az olması')));
  });

  test('no machine keys, refs or disclaimers reach the reader', () {
    for (final date in [DateTime(1990, 5, 14), DateTime(1998, 2, 21)]) {
      final text = _text(
        StarMapChartPortrait.build(_chart(date, time: date.add(const Duration(hours: 14))))!,
      );
      for (final bad in [
        'factRef', 'placement.', 'aspect.', '{', '_', 'fasıl', 'yaprak',
        'arşiv', 'kehanet', 'hüküm',
      ]) {
        expect(text, isNot(contains(bad)), reason: bad);
      }
    }
  });

  test('no evidence or non-Turkish language keeps existing copy', () {
    expect(StarMapChartPortrait.build(null), isNull);
    OraclyL10n.bind('en');
    addTearDown(() => OraclyL10n.bind('tr'));
    expect(
      StarMapChartPortrait.build(_chart(DateTime(1990, 5, 14))),
      isNull,
    );
  });
}
