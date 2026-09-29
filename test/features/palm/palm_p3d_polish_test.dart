/// P3D — palm loading identity, hand labels, and OR context language.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import 'package:oracly_new/features/palm/copy/palm_copy.dart';
import 'package:oracly_new/features/palm/models/palm_hand.dart';
import 'package:oracly_new/features/palm/models/palm_reading.dart';
import 'package:oracly_new/features/palm/presentation/palm_loading_view.dart';
import 'package:oracly_new/features/reading_operation/copy/reading_live_copy.dart';
import 'package:oracly_new/features/reading_operation/presentation/reading_wait_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('palm wait shows the hand copy, not the generic headline', (
    tester,
  ) async {
    OraclyL10n.bind('en');
    final message = PalmCopy.analyzing;
    final subtitle = PalmCopy.analyzingHint;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PalmLoadingView(message: message, subtitle: subtitle),
        ),
      ),
    );
    expect(find.text(message), findsOneWidget);
    expect(find.text(subtitle), findsOneWidget);
    expect(find.text(ReadingLiveCopy.headline), findsNothing);
  });

  testWidgets('shared wait stays generic when no feature copy is passed', (
    tester,
  ) async {
    OraclyL10n.bind('en');
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: ReadingWaitScreen(liveState: null)),
      ),
    );
    expect(find.text(ReadingLiveCopy.headline), findsOneWidget);
    expect(find.text(ReadingLiveCopy.subtitle), findsOneWidget);
  });

  test('hand labels follow the bound locale and keep wire identity', () {
    OraclyL10n.bind('tr');
    expect(PalmHand.left.label, 'SOL EL');
    expect(PalmHand.right.label, 'SAĞ EL');
    OraclyL10n.bind('en');
    expect(PalmHand.left.label, 'LEFT HAND');
    expect(PalmHand.right.label, 'RIGHT HAND');
    OraclyL10n.bind('ru');
    expect(PalmHand.left.label, 'ЛЕВАЯ РУКА');
    expect(PalmHand.right.label, 'ПРАВАЯ РУКА');
    expect(PalmHand.left.name, 'left');
    expect(PalmHand.right.name, 'right');
    expect(PalmHand.fromWire('left'), PalmHand.left);
    expect(PalmHand.fromWire('right'), PalmHand.right);
    expect(PalmHand.fromWire(null), isNull);
    expect(PalmHand.fromWire('unknown'), isNull);
  });

  test('OR palm context uses the bound language, not Turkish chrome', () {
    final reading = PalmReading(
      id: 'palm-1',
      createdAt: DateTime.utc(2026, 9, 29),
      hand: PalmHand.left,
      overall: 'A quiet palm.',
      heartLine: 'A close line.',
      takeaway: 'Leave it here.',
    );
    OraclyL10n.bind('en');
    final en = OracleReadingContextSources.palm(reading);
    expect(en.sourceLabel, 'Palm');
    expect(en.deckName, 'Palm');
    expect(en.readingTitle, PalmCopy.screenTitle);
    expect(en.spreadLabel, 'LEFT HAND');
    expect(en.fullInterpretation, contains('LEFT HAND'));
    expect(en.fullInterpretation, contains('A quiet palm.'));
    expect(en.fullInterpretation, isNot(contains('El Falı')));
    expect(en.fullInterpretation, isNot(contains('Genel:')));
    expect(en.fullInterpretation, isNot(contains('Sol el')));

    OraclyL10n.bind('ru');
    final ru = OracleReadingContextSources.palm(reading);
    expect(ru.sourceLabel, 'Ладонь');
    expect(ru.spreadLabel, 'ЛЕВАЯ РУКА');
    expect(ru.fullInterpretation, isNot(contains('El Falı')));

    OraclyL10n.bind('tr');
    final tr = OracleReadingContextSources.palm(reading);
    expect(tr.sourceLabel, 'El Falı');
    expect(tr.spreadLabel, 'SOL EL');
  });
}
