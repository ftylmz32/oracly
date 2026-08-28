/// Blind humanness gate — 50 texts, >25% generic per feature fails.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/reading/human_reader_blind_review.dart';

import 'human_reader_blind_samples.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('fifty blind samples stay human and specific', () async {
    final samples = await fiftyBlindSamples();
    expect(samples, hasLength(50));

    final report = HumanReaderBlindReview.review(samples);
    final failures = <String>[];

    for (final feature in report.features) {
      final name = feature.feature.name;
      final rate = (feature.genericRate * 100).toStringAsFixed(0);
      if (!feature.passes) {
        failures.add('$name: ${feature.genericCount}/${feature.total} generic ($rate%)');
      }
      for (final row in feature.samples) {
        expect(row.text.trim(), isNotEmpty, reason: name);
        if (row.marks.robotic && row.marks.generic) {
          failures.add('$name robotic+generic: ${row.text.substring(0, row.text.length.clamp(0, 80))}');
        }
      }
    }

    if (failures.isNotEmpty) {
      fail('Blind review failures:\n${failures.join('\n')}');
    }

    expect(report.passes, isTrue, reason: 'overall humanness');
  });

  test('blind review report breakdown', () async {
    final samples = await fiftyBlindSamples();
    final report = HumanReaderBlindReview.review(samples);
    for (final feature in report.features) {
      final g = feature.samples.where((s) => s.marks.generic).length;
      final s = feature.samples.where((s) => s.marks.specific).length;
      final h = feature.samples.where((s) => s.marks.human).length;
      final r = feature.samples.where((s) => s.marks.robotic).length;
      final p = feature.samples.where((s) => s.marks.personal).length;
      // ignore: avoid_print
      print(
        '${feature.feature.name}: GENERIC $g/${feature.total} '
        'SPECIFIC $s HUMAN $h ROBOTIC $r PERSONAL $p '
        '=> ${feature.passes ? 'PASS' : 'FAIL'}',
      );
    }
    // ignore: avoid_print
    print(
      'OVERALL HUMANNESS: ${report.passes ? 'PASS' : 'FAIL'} '
      '(${report.genericCount}/${report.total} generic)',
    );
  });
}
