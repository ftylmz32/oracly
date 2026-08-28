/// Takeaway flows from vision JSON through analysis models into UI fields.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/features/ai/production/models/palm_ai_analysis.dart';
import 'package:oracly_new/features/ai/production/openai/palm_vision_parser.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/presentation/palm_result_sections.dart';
import 'package:oracly_new/features/palm/services/palm_fortune_composer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('backend map -> PalmAiAnalysis -> toReading keeps takeaway', () {
    final parsed = PalmVisionParser.fromMap({
      'overall': 'Avuç sakin ve açık duruyor.',
      'takeaway': 'En net işaret yakınlık ritmi.',
      'heartLine': 'Kalp çizgisi yumuşak bir yay çiziyor.',
      'themes': ['yakınlık', 'denge'],
    });
    expect(parsed, isNotNull);
    expect(parsed!['takeaway'], 'En net işaret yakınlık ritmi.');

    final analysis = PalmAiAnalysis(
      overall: parsed['overall'] as String? ?? '',
      takeaway: parsed['takeaway'] as String? ?? '',
      heartLine: parsed['heartLine'] as String? ?? '',
      themes: (parsed['themes'] as List).cast<String>(),
    );
    final reading = analysis.toReading(
      id: 'palm_t1',
      createdAt: DateTime(2026, 8, 27),
      hand: PalmHand.right,
      imagePath: '/app/palm_images/palm_t1.jpg',
    );
    expect(reading.takeaway, 'En net işaret yakınlık ritmi.');
    expect(reading.themes, ['yakınlık', 'denge']);

    final composed = PalmFortuneComposer.compose(reading);
    expect(composed.takeaway, contains('yakınlık'));
  });

  testWidgets('result sections show takeaway title when present', (tester) async {
    final composed = PalmFortuneComposer.compose(
      PalmAiAnalysis(
        overall: 'Avuç sakin ve açık duruyor, çizgiler net okunuyor.',
        takeaway: 'En net işaret yakınlık ritmi burada.',
        themes: const ['yakınlık'],
      ).toReading(
        id: 'palm_ui',
        createdAt: DateTime(2026, 8, 27),
        hand: PalmHand.left,
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: PalmResultSections(reading: composed)),
      ),
    );
    await tester.pump();
    expect(find.text(PalmCopy.takeawayTitle), findsOneWidget);
    expect(find.text(PalmCopy.themesTitle), findsOneWidget);
    expect(find.textContaining('yakınlık'), findsWidgets);
  });
}
