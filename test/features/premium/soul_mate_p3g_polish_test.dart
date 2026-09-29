/// P3G — saved-portrait paywall flash, empty OR, redraw entitlement.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/premium_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/ai/oracle_conversation/models/oracle_reading_context_sources.dart';
import 'package:oracly_new/features/ai/oracle_conversation/widgets/or_ask_button.dart';
import 'package:oracly_new/features/premium/copy/soul_mate_copy.dart';
import 'package:oracly_new/features/premium/models/soul_mate_saved_result.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_opening.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_preview.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_result_view.dart';
import 'package:oracly_new/features/premium/presentation/screens/soul_mate_draw_screen.dart';
import 'package:oracly_new/features/premium/providers/soul_mate_saved_provider.dart';
import 'package:oracly_new/features/premium/services/soul_mate_draw_port.dart';
import 'package:oracly_new/features/premium/services/soul_mate_result_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../general_audit/g1/g1_soulmate_fakes.dart';
import '../../general_audit/g1/g1_soulmate_support.dart';

class _HeldJournal extends SoulMateResultService {
  _HeldJournal(super.storage);

  final gate = Completer<({SoulMateSavedResult meta, List<int> bytes})?>();

  @override
  Future<({SoulMateSavedResult meta, List<int> bytes})?> latestWithPortrait() =>
      gate.future;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<_HeldJournal> pumpHeld(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await LocalStorage.open();
    final held = _HeldJournal(storage);
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          soulMateResultServiceProvider.overrideWithValue(held),
        ],
        child: MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child ?? const SizedBox.shrink(),
          ),
          home: const SoulMateDrawScreen(),
        ),
      ),
    );
    await tester.pump();
    return held;
  }

  testWidgets(
    'a saved portrait is not announced as missing while restore runs',
    (tester) async {
      final held = await pumpHeld(tester);

      expect(find.byType(SoulMateDrawOpening), findsOneWidget);
      expect(find.byType(SoulMateDrawPreview), findsNothing);
      expect(find.text(PremiumCopy.unlockTitle), findsNothing);
      expect(find.text(SoulMateCopy.drawCta), findsNothing);

      held.gate.complete(null);
      await tester.pump();

      expect(find.byType(SoulMateDrawOpening), findsNothing);
      expect(find.byType(SoulMateDrawPreview), findsOneWidget);
      expect(find.text(PremiumCopy.unlockTitle), findsWidgets);
    },
  );

  testWidgets('opening and locked preview fit narrow screens', (tester) async {
    for (final size in const [Size(320, 568), Size(360, 640), Size(390, 844)]) {
      final held = await pumpHeld(tester, size: size);
      expect(tester.takeException(), isNull);
      expect(find.byType(SoulMateDrawOpening), findsOneWidget);
      held.gate.complete(null);
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.byType(SoulMateDrawPreview), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    }
    final held = await pumpHeld(
      tester,
      size: const Size(360, 640),
      textScale: 1.4,
    );
    expect(tester.takeException(), isNull);
    expect(find.byType(SoulMateDrawOpening), findsOneWidget);
    held.gate.complete(null);
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(find.byType(SoulMateDrawPreview), findsOneWidget);
  });

  testWidgets('a restored portrait stays readable without Premium', (
    tester,
  ) async {
    final held = await pumpHeld(tester);
    const parts = g1FullParts;
    held.gate.complete((
      meta: SoulMateSavedResult(
        id: 'saved-1',
        createdAt: DateTime(2026, 1, 2),
        name: 'Ada',
        birthDate: DateTime(1994, 3, 12),
        portraitPath: 'memory://saved-1',
        parts: parts,
      ),
      bytes: g1Png,
    ));
    await tester.pump();

    expect(find.byType(SoulMateDrawPreview), findsNothing);
    expect(find.text(PremiumCopy.unlockTitle), findsNothing);
    expect(find.byType(SoulMateDrawResultView), findsOneWidget);
    expect(find.byType(OrAskButton), findsOneWidget);
    expect(find.text(parts.energy), findsOneWidget);
  });

  testWidgets('missing interpretation does not open an empty OR handoff', (
    tester,
  ) async {
    final harness = await G1SoulMateHarness.open();
    final journal = G1MemorySoulMateJournal(harness.storage);
    await journal.saveSuccessfulDraw(
      request: SoulMateDrawRequest(
        name: 'Ada',
        birthDate: DateTime(1994, 3, 12),
      ),
      imageBytes: g1Png,
      recordId: 'partial',
      parts: g1PartialParts,
    );
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      harness.screen(
        extra: [soulMateResultServiceProvider.overrideWithValue(journal)],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(SoulMateDrawResultView), findsOneWidget);
    expect(find.text(SoulMateCopy.interpretationFailed), findsOneWidget);
    expect(find.byType(OrAskButton), findsNothing);
    expect(find.text(SoulMateCopy.redrawCta), findsOneWidget);
  });

  testWidgets('expired Premium cannot discard a saved portrait via redraw', (
    tester,
  ) async {
    final harness = await G1SoulMateHarness.open();
    final journal = G1MemorySoulMateJournal(harness.storage);
    await journal.saveSuccessfulDraw(
      request: SoulMateDrawRequest(
        name: 'Ada',
        birthDate: DateTime(1994, 3, 12),
      ),
      imageBytes: g1Png,
      recordId: 'kept',
      parts: g1FullParts,
    );
    await tester.binding.setSurfaceSize(const Size(390, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      harness.screen(
        extra: [soulMateResultServiceProvider.overrideWithValue(journal)],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(OrAskButton), findsOneWidget);

    harness.lapse();
    final hold = harness.verifier.hold = Completer<void>();
    final redraw = find.text(SoulMateCopy.redrawCta);
    final previousFatal = WidgetController.hitTestWarningShouldBeFatal;
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(
      () => WidgetController.hitTestWarningShouldBeFatal = previousFatal,
    );
    for (var i = 0; i < 12; i++) {
      final dy = tester.getTopLeft(redraw).dy;
      if (dy > 80 && dy < 1280) break;
      await tester.drag(find.byType(ListView), const Offset(0, -350));
      await tester.pump();
    }
    expect(tester.getTopLeft(redraw).dy, inInclusiveRange(80, 1320));
    await tester.tap(redraw);
    await tester.pump();

    expect(find.byType(SoulMateDrawResultView), findsOneWidget);
    expect(find.byType(SoulMateDrawPreview), findsNothing);

    hold.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(SoulMateDrawResultView), findsOneWidget);
    expect(find.byType(SoulMateDrawPreview), findsNothing);
    expect(find.text(SoulMateCopy.drawCta), findsNothing);
    expect(find.text(PremiumCopy.unlockTitle), findsWidgets);
    expect(journal.rows.keys, ['kept']);
    expect(harness.transport.creates, 0);
  });

  test('OR chrome follows locale and keeps the stored interpretation', () {
    const interpretation = 'quiet energy stays';
    contextFor(String code) {
      OraclyL10n.bind(code);
      return OracleReadingContextSources.soulMate(
        id: 'soulmate_saved-1',
        interpretation: interpretation,
        name: 'Ada',
      );
    }

    final tr = contextFor('tr');
    expect(tr.sourceLabel, 'Ruh Eşi');
    expect(tr.fullInterpretation, contains('İsim ilhamı: Ada'));
    expect(tr.fullInterpretation, contains(interpretation));
    expect(tr.fullInterpretation, isNot(contains('1994')));

    final en = contextFor('en');
    expect(en.sourceLabel, 'Soulmate');
    expect(en.spreadLabel, 'Symbolic portrait');
    expect(en.fullInterpretation, contains('Name inspiration: Ada'));
    expect(en.fullInterpretation, contains(interpretation));
    expect(en.fullInterpretation, isNot(contains('Ruh Eşi')));
    expect(en.fullInterpretation, isNot(contains('İsim ilhamı')));

    final ru = contextFor('ru');
    expect(ru.sourceLabel, 'Родственная душа');
    expect(ru.fullInterpretation, contains('Имя-вдохновение: Ada'));
    expect(ru.fullInterpretation, contains(interpretation));
    expect(ru.fullInterpretation, isNot(contains('Ruh Eşi')));
    expect(ru.fullInterpretation, isNot(contains('Kaynak:')));
  });
}
