/// Phase 7F — History Detail never regenerates / never calls Interpretation.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('history detail source firewall — local reopen only', () {
    final detail = File(
      'lib/features/tarot/presentation/screens/reading_history_detail_screen.dart',
    ).readAsStringSync();
    final body = File(
      'lib/features/tarot/presentation/screens/reading_history_detail_body.dart',
    ).readAsStringSync();
    final parser = File(
      'lib/features/tarot/presentation/utils/saved_reading_parser.dart',
    ).readAsStringSync();
    final blocks = File(
      'lib/features/tarot/presentation/utils/saved_reading_card_blocks.dart',
    ).readAsStringSync();

    for (final src in [detail, body, parser, blocks]) {
      expect(src.contains('resolveInterpretationContent'), isFalse);
      expect(src.contains('generateContent'), isFalse);
      expect(src.contains('generateResult'), isFalse);
      expect(src.contains('NarrativeTarotLiveInterpreter'), isFalse);
      expect(src.contains('TarotInterpretationService'), isFalse);
      expect(src.contains('chargeReading'), isFalse);
      expect(src.contains('recordCharge'), isFalse);
    }

    expect(detail.contains('ReadingGlassPanel'), isFalse);
    expect(body.contains('ReadingPremiumBody'), isTrue);
    expect(body.contains('showFlowProgress: false'), isTrue);
    expect(parser.contains("'Ters'"), isFalse);
    expect(parser.contains("'Düz'"), isFalse);
    expect(parser.contains('konumunda'), isFalse);
    expect(blocks.contains("'Ters'"), isFalse);
    expect(blocks.contains("'Düz'"), isFalse);
    expect(blocks.contains('konumunda'), isFalse);
  });
}
