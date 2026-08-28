/// First 60 seconds — a new user understands ORACLY without tutorials or a wall.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/first_session_copy.dart';
import 'package:oracly_new/core/copy/onboarding_copy.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/companion/copy/companion_copy.dart';
import 'package:oracly_new/features/companion/models/insight_request.dart';
import 'package:oracly_new/features/companion/models/reflection_context.dart';
import 'package:oracly_new/features/companion/presentation/reference/companion_reference_idle.dart';
import 'package:oracly_new/features/companion/services/companion_responder.dart';

void main() {
  setUp(() => OraclyL10n.bind('tr'));

  test('first 10 seconds name the place without a shop pitch', () {
    expect(OnboardingCopy.title, 'ORACLY');
    expect(
      OnboardingCopy.tagline,
      'Kendini farklı pencerelerden keşfet.',
    );
    expect(OnboardingCopy.pages, hasLength(1));
  });

  test('first 30 seconds lead into a skippable hello, not a reading wall', () {
    expect(OnboardingCopy.meetLabel, 'Seni tanıyalım');
    expect(OnboardingCopy.startFirstReading, 'İlk keşfine başla');
    expect(
      OnboardingCopy.setupSubtitle.toLowerCase(),
      contains('isteğe bağlı'),
    );
    expect(OnboardingCopy.nameLabel, isNotEmpty);
    expect(OnboardingCopy.birthLabel, isNotEmpty);
    expect(OnboardingCopy.languageLabel, isNotEmpty);
    expect(OnboardingCopy.styleLabel.toLowerCase(), contains('or'));
  });

  test('windows are named quietly, not a catalog', () {
    expect(OnboardingCopy.windows, [
      'Kahve',
      'El',
      'Gökyüzü',
      'Yıldızname',
      'Tarot',
      'OR',
    ]);
    expect(OnboardingCopy.tagline.toLowerCase(), isNot(contains('ruh eşi')));
    expect(OnboardingCopy.pages.first.subtitle, OnboardingCopy.tagline);
  });

  test('first 60 seconds invite a personal discovery then OR', () {
    expect(FirstSessionCopy.homeSubtitleNew.toLowerCase(), contains('kart'));
    expect(FirstSessionCopy.homeSubtitleNew.toLowerCase(), contains('kehanet'));
    expect(CompanionCopy.welcomeLine(name: 'Fatih'), contains('Fatih'));
    expect(CompanionCopy.idleTitle, isNot(contains('Fatih')));
    const responder = CompanionResponder();
    final selam = responder.respond(
      request: const InsightRequest(text: 'Selam'),
      context: const ReflectionContext(userName: 'Fatih'),
      personality: 'gentle',
    );
    expect(selam.body.trim(), isNotEmpty);
    expect(selam.body.length, lessThan(80));
    expect(selam.body.toLowerCase(), isNot(contains('kesin')));
    expect(selam.body.toLowerCase(), isNot(contains('nasıl yardımcı')));
  });

  test('onboarding completes with first-reading intent, not paywall', () {
    final source = File(
      'lib/features/onboarding/presentation/screens/onboarding_screen.dart',
    ).readAsStringSync();
    expect(source, contains('requestFirstReading'));
    expect(source, isNot(contains('showDialog')));
    expect(
      OnboardingCopy.pages.any((p) => p.title.contains('Premium')),
      isFalse,
    );
    expect(
      OnboardingCopy.startFirstReading.toLowerCase(),
      isNot(contains('abonelik')),
    );
  });

  testWidgets('OR idle stays universal; the name lives in the welcome line', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: CompanionReferenceIdle(onSelected: (_) {}, userName: 'Fatih'),
      ),
    );
    // Let the entrance stagger finish so no timer outlives the tree.
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text(CompanionCopy.presence), findsNothing);
    expect(find.text(CompanionCopy.idleTitle), findsOneWidget);
    expect(find.text(CompanionCopy.idleSubtitle), findsOneWidget);
    expect(find.textContaining('Fatih'), findsNothing);
    expect(CompanionCopy.welcomeLine(name: 'Fatih'), contains('Fatih'));
  });
}
