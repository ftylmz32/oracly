/// Real provider Palm readings, frozen with their human verdict. Verdicts are
/// truth metadata, NOT quality gates: they stop synthetic GOOD fixtures from
/// standing in for what the live product actually renders.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';

import 'palm_live_path_harness.dart';

const _real = {
  'test/features/palm/fixtures/real/palm_real_e3h1.json': 'WEAK',
  'test/features/palm/fixtures/real/palm_real_batch3a4.json': 'FAIL',
};

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  for (final MapEntry(key: path, value: verdict) in _real.entries) {
    final fixture = readJson(path);

    test('${fixture['id']} is real evidence with human verdict $verdict', () {
      expect(fixture['kind'], 'real_provider_output');
      expect(fixture['evidenceClass'], 'A');
      expect(fixture['humanVerdict'], verdict);
      expect(fixture['verdictIsQualityGate'], isFalse);
      expect(fixture['humanDefects'], isNotEmpty);
    });

    testWidgets('${fixture['id']} renders exactly its frozen output',
        (tester) async {
      final backend = publicPalm(fixture['backend'] as Map<String, dynamic>);
      final reading = composeLive(backend);
      expect(reading, isNotNull);
      final rendered = fixture['rendered'] as Map<String, dynamic>;
      await pumpSections(tester, reading!);
      expect(renderedTexts(tester), rendered['default']);
      await expandAll(tester);
      expect(renderedTexts(tester), rendered['expanded']);
    });
  }
}
