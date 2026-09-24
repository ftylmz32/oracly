/// Phase 6C — live call-site firewall (dormant infrastructure).
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializer / cache identity live call sites outside narrative = 0', () {
    final lib = Directory('lib');
    final hits = <String>[];
    for (final f in lib.listSync(recursive: true).whereType<File>()) {
      if (!f.path.endsWith('.dart')) continue;
      final norm = f.path.replaceAll('\\', '/');
      if (norm.contains('/features/tarot/narrative/')) continue;
      final text = f.readAsStringSync();
      if (text.contains('NarrativeTarotPromptSerializer') ||
          text.contains('NarrativeTarotCacheIdentity')) {
        hits.add(norm);
      }
    }
    expect(hits, isEmpty, reason: hits.join('\n'));
  });
}
