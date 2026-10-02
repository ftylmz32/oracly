/// Drives the live Palm client path over real backend public fields:
/// PalmVisionParser -> PalmAiAnalysis -> toReading -> PalmFortuneComposer
/// -> PalmResultSections. Never PalmFortuneNarration.
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/reading_ux/reading_ux_copy.dart';
import 'package:oracly_new/features/ai/production/ai_outcome.dart';
import 'package:oracly_new/features/ai/production/openai/openai_service_results.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/presentation/palm_result_sections.dart';
import 'package:oracly_new/features/palm/services/palm_fortune_composer.dart';

const palmPublicFields = [
  'visualObservation',
  'overall',
  'lifeLine',
  'headLine',
  'heartLine',
  'fateLine',
  'takeaway',
];

Map<String, dynamic> readJson(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

/// Same flattening as backend `toPublicPalm`: `{text, evidenceIds}` -> text.
Map<String, dynamic> publicPalm(Map<String, dynamic> narrative) => {
      for (final key in palmPublicFields)
        key: switch (narrative[key]) {
          final String text => text,
          {'text': final String text} => text,
          _ => '',
        },
      'symbols': const <String>[],
      'themes': const <String>[],
    };

PalmReading? composeLive(Map<String, dynamic> backend) =>
    OpenAiServiceResults.palm(AiOutcome.success(backend)).when(
      success: (analysis) => PalmFortuneComposer.compose(
        analysis.toReading(
          id: 'real-fixture',
          createdAt: DateTime(2026, 10, 3),
          hand: PalmHand.right,
          imagePath: null,
        ),
      ),
      error: (_) => null,
    );

Future<void> pumpSections(WidgetTester tester, PalmReading reading) async {
  tester.view.physicalSize = const Size(1170, 2532 * 6);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(child: PalmResultSections(reading: reading)),
    ),
  ));
  await tester.pumpAndSettle();
}

List<String> renderedTexts(WidgetTester tester) => [
      for (final widget in tester.allWidgets)
        if (widget is Text) (widget.data ?? widget.textSpan?.toPlainText() ?? '').trim(),
    ].where((text) => text.isNotEmpty).toList();

Future<void> expandAll(WidgetTester tester) async {
  final more = find.text(ReadingUxCopy.continueReading);
  for (var i = 0; i < 12 && more.evaluate().isNotEmpty; i++) {
    await tester.tap(more.first, warnIfMissed: false);
    await tester.pumpAndSettle();
  }
}
