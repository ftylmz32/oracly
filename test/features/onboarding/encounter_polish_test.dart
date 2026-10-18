/// Encounter polish: one name, honest interests, keyboard, short screens.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/onboarding_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../test_helpers/provider_scope_harness.dart';

Future<void> _pump(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  double scale = 1,
  bool reduced = false,
  double keyboard = 0,
}) async {
  await tester.binding.setSurfaceSize(size);
  final pixelRatio = tester.view.devicePixelRatio;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard * pixelRatio);
  addTearDown(tester.view.resetViewInsets);
  SharedPreferences.setMockInitialValues({});
  final storage = await LocalStorage.open();
  await tester.pumpWidget(
    buildProviderScopeHarness(
      storage: storage,
      child: MaterialApp(
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
              disableAnimations: reduced,
            ),
            child: const OnboardingScreen(),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _tap(WidgetTester tester, String label) async {
  final target = find.text(label).first;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target, warnIfMissed: false);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    OraclyL10n.bind('tr');
    AppLocale.debugDeviceLocale = () => const Locale('tr');
  });

  tearDown(() async {
    AppLocale.debugDeviceLocale = null;
  });

  testWidgets('empty name shows no sample and one inscription', (tester) async {
    await _pump(tester);
    await _tap(tester, OnboardingCopy.meetLabel);
    expect(find.text('Deniz'), findsNothing);
    expect(find.textContaining('memnun oldum'), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('long Turkish name is spoken once under the plate', (tester) async {
    await _pump(tester, size: const Size(320, 568), scale: 1.3);
    await _tap(tester, OnboardingCopy.meetLabel);
    const name = 'Ayşe Çağla Deniz';
    await tester.enterText(find.byType(TextField), name);
    await tester.pump();
    expect(find.text(OnboardingCopy.nameMet(name)), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('keyboard keeps the inscription above Devam', (tester) async {
    await _pump(tester, size: const Size(360, 640), keyboard: 280);
    await _tap(tester, OnboardingCopy.meetLabel);
    final field = tester.getRect(find.byType(TextField));
    final button = tester.getRect(find.text(OnboardingCopy.continueLabel));
    expect(field.top, greaterThan(0));
    expect(field.bottom, lessThan(button.top));
    expect(button.bottom, lessThanOrEqualTo(640));
  });

  testWidgets('several interests are not described as one', (tester) async {
    await _pump(tester);
    await _tap(tester, OnboardingCopy.meetLabel);
    await _tap(tester, OnboardingCopy.continueLabel);
    await _tap(tester, OnboardingCopy.interestLabel('love'));
    expect(find.text(OnboardingCopy.interestLine('love')), findsOneWidget);
    await _tap(tester, OnboardingCopy.interestLabel('future'));
    expect(find.text(OnboardingCopy.interestLines(['love', 'future'])), findsOneWidget);
    expect(find.text(OnboardingCopy.interestLine('love')), findsNothing);
    await _tap(tester, OnboardingCopy.interestLabel('love'));
    await _tap(tester, OnboardingCopy.interestLabel('future'));
    expect(find.text(OnboardingCopy.interestLine(null)), findsOneWidget);
  });

  testWidgets('long interest label wraps on a phone-width window', (tester) async {
    await _pump(tester, size: const Size(412, 915));
    await _tap(tester, OnboardingCopy.meetLabel);
    await _tap(tester, OnboardingCopy.continueLabel);
    final label = OnboardingCopy.interestLabel('future');
    final rect = tester.getRect(find.text(label));
    expect(rect.height, greaterThan(24), reason: 'w=${rect.width} h=${rect.height}');
    expect((tester.renderObject(find.text(label)) as dynamic).didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long interest label wraps inside the window at 1.3x', (tester) async {
    await _pump(tester, size: const Size(320, 568), scale: 1.3);
    await _tap(tester, OnboardingCopy.meetLabel);
    await _tap(tester, OnboardingCopy.continueLabel);
    final label = OnboardingCopy.interestLabel('future');
    final rect = tester.getRect(find.text(label));
    expect(rect.height, greaterThan(20));
    expect((tester.renderObject(find.text(label)) as dynamic).didExceedMaxLines, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('welcome speaks the name only in the greeting', (tester) async {
    await _pump(tester, reduced: true);
    await _tap(tester, OnboardingCopy.meetLabel);
    await tester.enterText(find.byType(TextField), 'Ayşe');
    await tester.pump();
    await _tap(tester, OnboardingCopy.continueLabel);
    await _tap(tester, OnboardingCopy.interestLabel('love'));
    await _tap(tester, OnboardingCopy.continueLabel);
    expect(find.text(OnboardingCopy.skyHelp), findsOneWidget);
    expect(find.textContaining('doğum gününü bırak'), findsNothing);
    await _tap(tester, OnboardingCopy.continueLabel);
    expect(find.text(OnboardingCopy.welcomeTitle('Ayşe')), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    expect(find.text(OnboardingCopy.welcomeLine('love')), findsOneWidget);
    expect(find.text(OnboardingCopy.passLabel), findsNothing);
  });
}
