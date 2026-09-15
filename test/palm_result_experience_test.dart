/// Palm result experience — real hand, grounded story, optional line asides.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/copy/fortune_voice.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/presentation/palm_result_photo.dart';
import 'package:oracly_new/features/palm/presentation/palm_result_sections.dart';
import 'package:oracly_new/features/palm/presentation/palm_result_view.dart';
import 'package:oracly_new/features/palm/services/palm_fortune_composer.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('story uses observed geometry, never textbook or medical claims', () {
    // BATCH 3A.2: overall must clear the composer's own trust/quality bar
    // (>=40 chars, no robotic/certainty/dump text) for compose() to
    // return a reading at all; the actual subject of this test —
    // per-line textbook/medical filtering — is unrelated to that bar and
    // still lives in PalmObservation.line(), untouched by this batch.
    final reading = PalmFortuneComposer.compose(
      PalmReading(
        id: 'geo',
        createdAt: DateTime(2026, 8, 18),
        hand: PalmHand.right,
        overall:
            'Avuç açık ve sakin duruyor; çizgiler net okunuyor, hızlı '
            'değil, temkinli bir tempo hissettiriyor.',
        heartLine: 'Kalp çizgisi belirgin.',
        headLine: 'Kalp çizgisi duyguları temsil eder.',
        lifeLine: 'Yaşam çizgisi uzun ömür demektir.',
      ),
    )!;
    expect(reading.overall.toLowerCase(), contains('açık'));
    expect(reading.heartLine.toLowerCase(), contains('belirgin'));
    expect(reading.headLine, isEmpty);
    expect(reading.lifeLine, isEmpty);
    expect(reading.overall.toLowerCase(), isNot(contains('temsil eder')));
    expect(reading.overall.toLowerCase(), isNot(contains('ömür')));
    expect(FortuneVoice.claimsMedical(reading.fullText), isFalse);
  });

  testWidgets('real hand photo sits above the spoken reading', (tester) async {
    final file = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}oracly_palm_hero.jpg',
    );
    file.writeAsBytesSync(const [0xFF, 0xD8, 0xFF, 0xD9]);
    addTearDown(() {
      try {
        if (file.existsSync()) file.deleteSync();
      } on FileSystemException {
        // Windows keeps decoded image bytes locked; a 4-byte temp file is fine.
      }
    });

    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [localStorageProvider.overrideWithValue(storage)],
        child: MaterialApp(
          home: Scaffold(
            body: PalmResultView(
              reading: PalmReading(
                id: 'hero',
                createdAt: DateTime(2026, 8, 18),
                hand: PalmHand.right,
                imagePath: file.path,
                overall: 'Avuç açık ve sakin duruyor.',
                heartLine: 'Kalp çizgisi belirgin.',
              ),
              onNewPalm: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final photo = tester.getTopLeft(find.byType(PalmResultPhoto));
    final heading = tester.getTopLeft(find.text(PalmCopy.overallTitle));
    expect(photo.dy, lessThan(heading.dy));
    expect(find.byType(PalmResultSections), findsOneWidget);
    expect(find.text(PalmCopy.heartTitle), findsOneWidget);
    expect(find.text(PalmCopy.headTitle), findsNothing);
  });
}
