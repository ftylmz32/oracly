/// RELIABILITY BATCH 2B — Fix 2: My Story must not turn a load error into
/// fake empty content.
///
/// Previously `personalDiscoveryProfileProvider.when(error: ...)` rendered
/// a story built from `PersonalDiscoveryProfile.empty` — a real loading
/// failure looked identical to "you simply have no story yet". The fix
/// renders the shared `OraclyErrorState` (with a real retry that
/// invalidates the provider) on error, distinct from both the populated
/// and the legitimately-empty data states.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/my_story/copy/my_story_copy.dart';
import 'package:oracly_new/features/my_story/presentation/screens/my_story_screen.dart';
import 'package:oracly_new/features/personal_discovery/copy/personal_theme_copy.dart';
import 'package:oracly_new/features/personal_discovery/models/cross_discovery_insight.dart';
import 'package:oracly_new/features/personal_discovery/models/discovery_theme_strength.dart';
import 'package:oracly_new/features/personal_discovery/models/personal_discovery_profile.dart';
import 'package:oracly_new/features/personal_discovery/providers/personal_discovery_providers.dart';
import 'package:oracly_new/shared/widgets/oracly_error_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('tr'));

  Future<void> pump(
    WidgetTester tester, {
    required Override profileOverride,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [profileOverride],
        child: const MaterialApp(home: MyStoryScreen()),
      ),
    );
    await tester.pump();
  }

  testWidgets('A: a populated profile renders the real story', (tester) async {
    final profile = PersonalDiscoveryProfile(
      crossInsights: [
        CrossDiscoveryInsight(
          theme: 'değişim',
          sources: const ['coffee', 'dream'],
          confidence: DiscoveryThemeStrength.recurring,
          lastObserved: DateTime(2026, 8, 14),
          sourceCount: 2,
          discoveryCount: 3,
          recencyWeight: 0.9,
        ),
      ],
    );

    await pump(
      tester,
      profileOverride: personalDiscoveryProfileProvider.overrideWith(
        (ref) async => profile,
      ),
    );

    expect(find.text(PersonalThemeCopy.crossModal(['değişim'])), findsOneWidget);
    expect(find.byType(OraclyErrorState), findsNothing);
  });

  testWidgets(
    'B: a legitimately empty profile shows the honest empty narrative, not an error',
    (tester) async {
      await pump(
        tester,
        profileOverride: personalDiscoveryProfileProvider.overrideWith(
          (ref) async => PersonalDiscoveryProfile.empty,
        ),
      );

      expect(find.text(PersonalThemeCopy.insufficient), findsOneWidget);
      expect(find.byType(OraclyErrorState), findsNothing);
      expect(find.text(ResilienceCopy.genericLoadFailed), findsNothing);
    },
  );

  testWidgets(
    'C: a provider failure shows the error state, never the fabricated empty narrative',
    (tester) async {
      await pump(
        tester,
        profileOverride: personalDiscoveryProfileProvider.overrideWith(
          (ref) async => throw StateError('storage unavailable'),
        ),
      );

      expect(find.byType(OraclyErrorState), findsOneWidget);
      expect(find.text(MyStoryCopy.loadFailed), findsOneWidget);
      // Must not silently masquerade as "you have no story yet".
      expect(find.text(PersonalThemeCopy.insufficient), findsNothing);
      // Must not leak the raw exception text.
      expect(find.textContaining('storage unavailable'), findsNothing);
      expect(find.textContaining('StateError'), findsNothing);
    },
  );

  testWidgets('D: Retry on the error state actually invalidates the provider', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          personalDiscoveryProfileProvider.overrideWith((ref) async {
            calls++;
            throw StateError('storage unavailable');
          }),
        ],
        child: const MaterialApp(home: MyStoryScreen()),
      ),
    );
    await tester.pump();
    expect(calls, 1);
    expect(find.byType(OraclyErrorState), findsOneWidget);

    await tester.tap(find.text(ResilienceCopy.retryAction));
    await tester.pump();

    // Invalidating re-runs the provider — a real reload, not a UI-only reset.
    expect(calls, 2);
  });

  testWidgets(
    'E: a successful retry replaces the error state with real content',
    (tester) async {
      var shouldFail = true;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            personalDiscoveryProfileProvider.overrideWith((ref) async {
              if (shouldFail) throw StateError('storage unavailable');
              return PersonalDiscoveryProfile.empty;
            }),
          ],
          child: const MaterialApp(home: MyStoryScreen()),
        ),
      );
      await tester.pump();
      expect(find.byType(OraclyErrorState), findsOneWidget);

      shouldFail = false;
      await tester.tap(find.text(ResilienceCopy.retryAction));
      await tester.pump();
      await tester.pump();

      expect(find.byType(OraclyErrorState), findsNothing);
      expect(find.text(PersonalThemeCopy.insufficient), findsOneWidget);
    },
  );
}
