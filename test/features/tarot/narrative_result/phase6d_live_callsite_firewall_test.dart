/// Phase 6D — live call-site firewall for wire/result packages.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Narrative wire/result live call sites outside package = 0', () {
    final lib = Directory('lib');
    final hits = <String>[];
    const needles = [
      'NarrativeTarotWireContract',
      'NarrativeTarotResultParser',
      'NarrativeTarotQualityValidator',
      'NarrativeTarotResultBridge',
    ];
    for (final f in lib.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final norm = f.path.replaceAll('\\', '/');
      if (norm.contains('/features/tarot/narrative/transport/') ||
          norm.contains('/features/tarot/narrative/result/') ||
          norm.contains('/features/tarot/narrative/shadow/')) {
        continue;
      }
      final text = f.readAsStringSync();
      for (final n in needles) {
        if (text.contains(n)) {
          hits.add('$norm::$n');
        }
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}
