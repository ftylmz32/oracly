/// Soulmate prerequisite release blocker -- Tarot deck-ready Continue must
/// never strand the user in permanent loading.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/app/providers/app_providers.dart';
import 'package:oracly_new/core/copy/resilience_copy.dart';
import 'package:oracly_new/core/data/datasources/local_storage.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/core/theme/app_theme.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_flow_controller.dart';
import 'package:oracly_new/features/tarot/controllers/tarot_reading_controller.dart';
import 'package:oracly_new/features/tarot/data/repositories/tarot_reading_repository_impl.dart';
import 'package:oracly_new/features/tarot/domain/models/reading_session.dart';
import 'package:oracly_new/features/tarot/domain/models/tarot_spread.dart';
import 'package:oracly_new/features/tarot/domain/repositories/tarot_reading_repository.dart';
import 'package:oracly_new/features/tarot/ritual/screens/tarot_ritual_deck_ready_screen.dart';
import 'package:oracly_new/features/tarot/shared/tarot_scope.dart';
import 'package:oracly_new/shared/widgets/oracly_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('tr'));

  Future<
    ({
      _FailableRepo repo,
      TarotReadingController reading,
      TarotFlowController flow,
    })
  >
  pumpDeckReady(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final storage = LocalStorage(await SharedPreferences.getInstance());
    final repo = _FailableRepo(
      TarotReadingRepositoryImpl.fromStorage(storage),
    );
    final reading = TarotReadingController(repository: repo);
    addTearDown(reading.dispose);
    final flow = TarotFlowController();
    addTearDown(flow.dispose);
    flow.selectSpread(TarotSpreadType.single);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
          selectedSpreadProvider.overrideWith(
            (ref) => TarotSpreadType.single.label,
          ),
          selectedDeckProvider.overrideWith((ref) => 'classic'),
        ],
        child: TarotScope(
          flow: flow,
          reading: reading,
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const TarotRitualDeckReadyScreen(),
          ),
        ),
      ),
    );
    await tester.pump();
    return (repo: repo, reading: reading, flow: flow);
  }

  // The button's own label is replaced by a spinner while loading, so
  // find it by type -- stable across both visual states.
  Finder continueButton() => find.byType(OraclyButton);

  testWidgets(
    'success starts exactly one session and advances the flow',
    (tester) async {
      final ctx = await pumpDeckReady(tester);
      final savesBefore = ctx.repo.saveCount;

      await tester.tap(continueButton());
      await tester.pump();
      // ShuffleScreen's own ritual bootstrap runs a one-shot ~280ms timer on
      // mount (which itself advances the flow again, to cardSelection); let
      // it settle so the test binding doesn't see a pending timer.
      await tester.pump(const Duration(milliseconds: 400));

      expect(ctx.reading.session, isNotNull);
      expect(ctx.reading.session!.flowStep, isNot(ReadingFlowStep.deckSelection));
      expect(ctx.repo.saveCount, greaterThan(savesBefore));
    },
  );

  testWidgets('rapid duplicate taps start exactly one session', (
    tester,
  ) async {
    final ctx = await pumpDeckReady(tester);
    ctx.repo.delaySaves = const Duration(milliseconds: 100);

    await tester.tap(continueButton());
    await tester.pump();
    // Still mid-flight (loading is true) -- further taps must be no-ops.
    await tester.tap(continueButton(), warnIfMissed: false);
    await tester.tap(continueButton(), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 200));

    expect(ctx.reading.session, isNotNull);
    final sessionId = ctx.reading.session!.id;
    await tester.pump(const Duration(milliseconds: 400));
    expect(ctx.reading.session!.id, sessionId);
  });

  testWidgets(
    'persistence failure clears loading and shows a retryable error',
    (tester) async {
      final ctx = await pumpDeckReady(tester);
      ctx.repo.failNextSaves = 1;

      await tester.tap(continueButton());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Real error surfaced -- not stuck in loading, not a fake success.
      expect(find.text(ResilienceCopy.sessionInitFailed), findsOneWidget);
      expect(find.text(ResilienceCopy.retryAction), findsOneWidget);
      expect(find.byType(TarotRitualDeckReadyScreen), findsOneWidget);

      // Continue itself is tappable again -- loading truly cleared, not
      // just the snackbar's own retry action.
      await tester.tap(continueButton());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(ctx.reading.session, isNotNull);
    },
  );

  testWidgets('retry after failure succeeds without a duplicate session', (
    tester,
  ) async {
    final ctx = await pumpDeckReady(tester);
    ctx.repo.failNextSaves = 1;

    await tester.tap(continueButton());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(ResilienceCopy.retryAction), findsOneWidget);
    // A session was created in-memory before the persist failure, but the
    // flow never advanced past its initial step -- this is the same
    // "grounded, not fake" invariant as a session that never started.
    expect(ctx.reading.session!.flowStep, ReadingFlowStep.deckSelection);

    // Let the snackbar's entrance animation settle before hit-testing it.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text(ResilienceCopy.retryAction));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(ctx.reading.session, isNotNull);
    expect(ctx.reading.session!.flowStep, isNot(ReadingFlowStep.deckSelection));
  });
}

class _FailableRepo implements TarotReadingRepository {
  _FailableRepo(this._inner);

  final TarotReadingRepository _inner;
  int saveCount = 0;
  int failNextSaves = 0;
  Duration? delaySaves;

  @override
  Future<void> saveSession(ReadingSession session) async {
    if (delaySaves != null) await Future<void>.delayed(delaySaves!);
    saveCount++;
    if (failNextSaves > 0) {
      failNextSaves--;
      throw StateError('persist_failed');
    }
    await _inner.saveSession(session);
  }

  @override
  Future<void> clearActiveSession() => _inner.clearActiveSession();

  @override
  Future<void> deleteSession(String id) => _inner.deleteSession(id);

  @override
  Future<ReadingSession?> loadActiveSession() => _inner.loadActiveSession();

  @override
  Future<List<ReadingSession>> loadAllSessions() => _inner.loadAllSessions();

  @override
  Future<List<ReadingSession>> loadCompletedSessions() =>
      _inner.loadCompletedSessions();

  @override
  Future<ReadingSession?> loadSession(String id) => _inner.loadSession(id);
}
