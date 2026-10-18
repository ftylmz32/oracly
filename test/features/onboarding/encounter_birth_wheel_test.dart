/// Encounter V2.4A: three-column birth wheel — Vazgeç keeps, Onayla saves.
library;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/onboarding_copy.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/onboarding/data/onboarding_setup_draft.dart';
import 'package:oracly_new/features/onboarding/encounter/encounter_birth_wheel.dart';
import 'package:oracly_new/features/onboarding/encounter/encounter_sky_scene.dart';
import 'package:oracly_new/features/premium/models/personalization_models.dart';

final _today = DateTime(2026, 10, 17);

/// Mirrors OraclyApp: Turkish copy over English Material chrome.
Widget _app(Widget home, {double scale = 1}) => MaterialApp(
  locale: AppLocale.materialLocale('tr'),
  supportedLocales: const [Locale('tr'), Locale('en'), Locale('ru')],
  localizationsDelegates: const [
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
      child: Scaffold(body: home),
    ),
  ),
);

class _Host extends StatelessWidget {
  const _Host({required this.initial, required this.onResult});

  final DateTime? initial;
  final void Function(DateTime?) onResult;

  @override
  Widget build(BuildContext context) => Center(
    child: TextButton(
      onPressed: () async => onResult(
        await showEncounterBirthWheel(context, initial: initial, today: _today),
      ),
      child: const Text('open'),
    ),
  );
}

Future<List<DateTime?>> _open(
  WidgetTester tester, {
  DateTime? initial,
  Size size = const Size(390, 844),
  double scale = 1,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final results = <DateTime?>[];
  await tester.pumpWidget(
    _app(_Host(initial: initial, onResult: results.add), scale: scale),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return results;
}

/// Drags one column by whole rows; positive rows move toward later values.
Future<void> _roll(WidgetTester tester, String label, int rows) async {
  await tester.drag(
    find.text(label).last,
    Offset(0, -44.0 * rows),
    warnIfMissed: false,
  );
  await _settle(tester);
}

/// Fixed frames: the sky hero never settles.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _press(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await _settle(tester);
}

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  testWidgets('wheel opens with three columns, day-month-year, no keyboard', (
    tester,
  ) async {
    await _open(tester, initial: DateTime(1994, 6, 12));
    final picker = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    expect(picker.mode, CupertinoDatePickerMode.date);
    expect(picker.dateOrder, DatePickerDateOrder.dmy);
    expect(picker.initialDateTime, DateTime(1994, 6, 12));
    expect(find.byType(CupertinoPicker), findsNWidgets(3));
    expect(find.byType(EditableText), findsNothing);
    expect(find.text(OnboardingCopy.birthCancel), findsOneWidget);
    expect(find.text(OnboardingCopy.birthConfirm), findsOneWidget);
    expect(OnboardingCopy.birthCancel, 'Vazgeç');
    expect(OnboardingCopy.birthConfirm, 'Onayla');
    expect(find.text('Haziran'), findsWidgets);
    expect(find.text('June'), findsNothing);
  });

  testWidgets('Onayla returns the rolled date as a local midnight', (tester) async {
    final results = await _open(tester, initial: DateTime(1994, 6, 12));
    await _roll(tester, '12', 3);
    await _roll(tester, '1994', 2);
    await _press(tester, OnboardingCopy.birthConfirm);
    expect(results, [DateTime(1996, 6, 15)]);
    final picked = results.single!;
    expect(picked.isUtc, isFalse);
    expect([picked.hour, picked.minute, picked.second], [0, 0, 0]);
  });

  testWidgets('Vazgeç returns nothing even after rolling', (tester) async {
    final results = await _open(tester, initial: DateTime(1994, 6, 12));
    await _roll(tester, '1994', 3);
    await _press(tester, OnboardingCopy.birthCancel);
    expect(results, [null]);
  });

  testWidgets('29 Şubat holds, and a non-leap year rolls it to 28', (
    tester,
  ) async {
    var results = await _open(tester, initial: DateTime(2000, 2, 29));
    await _press(tester, OnboardingCopy.birthConfirm);
    expect(results, [DateTime(2000, 2, 29)]);

    results = await _open(tester, initial: DateTime(2000, 2, 29));
    await _roll(tester, '2000', 1);
    await _press(tester, OnboardingCopy.birthConfirm);
    expect(results, [DateTime(2001, 2, 28)]);
  });

  testWidgets('30-day month never yields 31', (tester) async {
    final results = await _open(tester, initial: DateTime(1990, 3, 31));
    await _roll(tester, '1990', 0);
    final month = find.descendant(
      of: find.byType(CupertinoPicker).at(1),
      matching: find.text('Mart'),
    );
    await tester.drag(month, const Offset(0, -44), warnIfMissed: false);
    await tester.pumpAndSettle();
    await _press(tester, OnboardingCopy.birthConfirm);
    expect(results, [DateTime(1990, 4, 30)]);
  });

  testWidgets('future dates cannot be confirmed', (tester) async {
    var results = await _open(tester, initial: DateTime(2030, 1, 1));
    await _press(tester, OnboardingCopy.birthConfirm);
    expect(results, [_today]);

    results = await _open(tester, initial: _today);
    await _roll(tester, '2026', 2);
    await _roll(tester, '17', 5);
    await _press(tester, OnboardingCopy.birthConfirm);
    expect(results.single!.isAfter(_today), isFalse);
  });

  testWidgets('stored date with a clock time or UTC keeps its calendar day', (
    tester,
  ) async {
    final stored = DateTime.parse('1988-11-03T00:00:00.000Z');
    final results = await _open(tester, initial: stored);
    await _press(tester, OnboardingCopy.birthConfirm);
    expect(results, [DateTime(1988, 11, 3)]);
    expect(encounterDay(DateTime(1988, 11, 3, 23, 59)), DateTime(1988, 11, 3));
  });

  for (final width in [320.0, 360.0, 390.0, 412.0]) {
    testWidgets('fits ${width.toInt()} px at 1.3 text scale', (tester) async {
      await _open(
        tester,
        initial: DateTime(1994, 8, 12),
        size: Size(width, 700),
        scale: 1.3,
      );
      expect(tester.takeException(), isNull);
      final button = tester.getSize(
        find.ancestor(
          of: find.text(OnboardingCopy.birthConfirm),
          matching: find.byType(Container),
        ).first,
      );
      expect(button.height, greaterThanOrEqualTo(48));
      expect(find.text('Ağustos'), findsWidgets);
    });
  }

  group('sky scene', () {
    OnboardingSetupDraft draft({DateTime? birthDate}) => OnboardingSetupDraft(
      updatedAtMillis: 0,
      language: 'tr',
      style: AiPersonality.values.first,
      scene: 3,
      birthDate: birthDate,
    );

    Future<List<OnboardingSetupDraft>> pumpScene(
      WidgetTester tester,
      OnboardingSetupDraft value,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final changes = <OnboardingSetupDraft>[];
      await tester.pumpWidget(
        _app(
          EncounterSkyScene(
            draft: value,
            onChanged: changes.add,
            onContinue: () {},
            onSkip: () {},
            onBack: () {},
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));
      return changes;
    }

    Future<void> openRow(WidgetTester tester, String value) async {
      final row = find.text(value);
      await tester.ensureVisible(row);
      await tester.tap(row);
      await _settle(tester);
    }

    testWidgets('nothing is saved until the wheel is confirmed', (tester) async {
      final changes = await pumpScene(tester, draft());
      expect(find.text(OnboardingCopy.birthPick), findsOneWidget);
      expect(changes, isEmpty);
      await openRow(tester, OnboardingCopy.birthPick);
      await _press(tester, OnboardingCopy.birthCancel);
      expect(changes, isEmpty);
    });

    testWidgets('saved date opens in the wheel; Onayla updates only the date', (
      tester,
    ) async {
      final saved = DateTime(1992, 2, 29);
      final changes = await pumpScene(tester, draft(birthDate: saved));
      await openRow(tester, OraclyFormat.date(saved));
      final picker = tester.widget<CupertinoDatePicker>(
        find.byType(CupertinoDatePicker),
      );
      expect(picker.initialDateTime, saved);
      await _roll(tester, '1992', 1);
      await _press(tester, OnboardingCopy.birthConfirm);
      expect(changes, hasLength(1));
      expect(changes.single.birthDate, DateTime(1993, 2, 28));
      expect(changes.single.birthTimeKnown, isFalse);
      expect(changes.single.birthPlaceTr, isNull);
    });
  });
}
