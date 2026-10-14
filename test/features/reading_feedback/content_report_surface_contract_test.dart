import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all eight AI experiences expose in-app report access', () {
    final contracts = <String, RegExp>{
      'lib/features/coffee/presentation/reference/coffee_result_actions.dart':
          RegExp(r'ReadingQualityActions'),
      'lib/features/palm/presentation/palm_result_actions.dart': RegExp(
        r'ReadingQualityActions',
      ),
      'lib/features/tarot/presentation/screens/reading_screen.dart': RegExp(
        r'ReadingQualityActions',
      ),
      'lib/features/astrology/presentation/reference/astrology_reference_detail_body.dart':
          RegExp(r'ReadingQualityActions'),
      'lib/features/star_map/presentation/reference/star_map_result_footer.dart':
          RegExp(r'ReadingQualityActions'),
      'lib/features/dream/presentation/reference/dream_reference_result_actions.dart':
          RegExp(r'ReadingQualityActions'),
      'lib/features/premium/presentation/screens/soul_mate_result_epilogue.dart':
          RegExp(r'ReadingQualityActions'),
      'lib/features/companion/presentation/reference/companion_or_message_actions.dart':
          RegExp(r'ReadingFeedbackOpener\.open'),
    };
    for (final entry in contracts.entries) {
      expect(
        File(entry.key).readAsStringSync(),
        matches(entry.value),
        reason: entry.key,
      );
    }
  });
}
