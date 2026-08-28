/// Final content gate — 90 real outputs across all reading surfaces.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/reading/human_reader_blind_review.dart';

import 'human_reader_ninety_samples.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('ninety real outputs stay specific, human, and honest', () async {
    final samples = await ninetyBlindSamples();
    expect(samples, hasLength(90));

    final byFeature = <BlindFeature, int>{};
    for (final s in samples) {
      byFeature[s.feature] = (byFeature[s.feature] ?? 0) + 1;
    }
    expect(byFeature[BlindFeature.coffee], 10);
    expect(byFeature[BlindFeature.palm], 10);
    expect(byFeature[BlindFeature.dream], 10);
    expect(byFeature[BlindFeature.tarot], 10);
    expect(byFeature[BlindFeature.astrology], 10);
    expect(byFeature[BlindFeature.starMap], 10);
    expect(byFeature[BlindFeature.soulMate], 10);
    expect(byFeature[BlindFeature.orCompanion], 20);

    final report = HumanReaderBlindReview.review(samples);
    final failures = <String>[];

    for (final feature in report.features) {
      final name = feature.feature.name;
      final rate = (feature.genericRate * 100).toStringAsFixed(0);
      // ignore: avoid_print
      print(
        '$name: GENERIC ${feature.genericCount}/${feature.total} ($rate%) '
        'CERT ${feature.certaintyCount} LEAK ${feature.identityLeakCount} '
        '=> ${feature.passes ? 'PASS' : 'FAIL'}',
      );
      if (!feature.passes) {
        failures.add(
          '$name: generic=${feature.genericCount}/${feature.total} '
          'certainty=${feature.certaintyCount} leak=${feature.identityLeakCount}',
        );
        for (final row in feature.samples) {
          if (row.marks.generic ||
              row.marks.falseCertainty ||
              row.marks.identityLeak) {
            failures.add('  · ${_clip(row.text)}');
          }
        }
      }
    }

    // ignore: avoid_print
    print(
      'OVERALL: ${report.passes ? 'PASS' : 'FAIL'} '
      '(${report.genericCount}/${report.total} generic)',
    );
    expect(report.passes, isTrue, reason: failures.join('\n'));
  });
}

String _clip(String text) {
  final t = text.replaceAll('\n', ' ').trim();
  return t.length <= 100 ? t : '${t.substring(0, 100)}…';
}
