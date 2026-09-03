/// D2 — Tarot post-reveal Continue reliability.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/copy/reading_flow_copy.dart';
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
import 'package:oracly_new/features/tarot/presentation/screens/card_reveal_screen.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/card_reveal_spread.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/reveal_result_panel.dart';
import 'package:oracly_new/features/tarot/presentation/widgets/card_reveal/reveal_result_panel_chrome.dart';
import 'package:oracly_new/features/tarot/shared/tarot_scope.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => OraclyL10n.bind('en'));

  group('advanceAfterReveal restore', () {
    late _CountingRepo repo;
    late TarotReadingController reading;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      repo = _CountingRepo(TarotReadingRepositoryImpl.fromStorage(storage));
      reading = TarotReadingController(repository: repo);
    });

    tearDown(() => reading.dispose());

    Future<void> toReveal({int cards = 1, bool queued = false}) async {
      await reading.beginSession(
        spread: cards == 1 ? TarotSpreadType.single : TarotSpreadType.threeCard,
        deckId: 'classic',
      );
      await reading.advanceToShuffle();
      await reading.performShuffle();
      await reading.finishShuffle();
      if (queued) {
        await reading.drawAllRemaining();
      } else {
        for (var i = 0; i < cards; i++) {
          await reading.drawCard();
        }
      }
      expect(reading.session!.flowStep, ReadingFlowStep.reveal);
    }

    test('success advances to reading once', () async {
      await toReveal();
      final id = reading.session!.id;
      final savesBefore = repo.saveCount;
      await reading.advanceAfterReveal();
      expect(reading.session!.id, id);
      expect(reading.session!.flowStep, ReadingFlowStep.reading);
      expect(reading.session!.drawnCards, hasLength(1));
      expect(repo.saveCount, greaterThan(savesBefore));
    });

    test(
      'failure restores session; retry succeeds without new cards',
      () async {
        await toReveal(cards: 3, queued: true);
        final id = reading.session!.id;
        final cards = reading.session!.drawnCards
            .map((c) => c.card.id)
            .toList();
        final position = reading.session!.currentPositionIndex;
        final savesBefore = repo.saveCount;

        repo.failNextSaves = 1;
        await expectLater(
          reading.advanceAfterReveal(),
          throwsA(isA<StateError>()),
        );
        expect(reading.session!.id, id);
        expect(reading.session!.flowStep, ReadingFlowStep.reveal);
        expect(reading.session!.currentPositionIndex, position);
        expect(
          reading.session!.drawnCards.map((c) => c.card.id).toList(),
          cards,
        );

        await reading.advanceAfterReveal();
        expect(reading.session!.id, id);
        expect(
          reading.session!.drawnCards.map((c) => c.card.id).toList(),
          cards,
        );
        expect(reading.session!.currentPositionIndex, position + 1);
        expect(repo.saveCount, greaterThan(savesBefore));
      },
    );

    test('repeated advance while fail does not skip identity', () async {
      await toReveal(cards: 3, queued: true);
      final id = reading.session!.id;
      repo.failNextSaves = 2;
      await expectLater(
        reading.advanceAfterReveal(),
        throwsA(isA<StateError>()),
      );
      await expectLater(
        reading.advanceAfterReveal(),
        throwsA(isA<StateError>()),
      );
      expect(reading.session!.id, id);
      expect(reading.session!.flowStep, ReadingFlowStep.reveal);
      expect(reading.session!.drawnCards, hasLength(3));
    });
  });

  group('Continue CTA UI', () {
    final data = CardRevealSpread.cards.first;

    Future<void> pumpPanel(
      WidgetTester tester, {
      required Size size,
      required bool busy,
      String? error,
      int taps = 0,
    }) async {
      var calls = 0;
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: MediaQuery(
            data: MediaQueryData(size: size, disableAnimations: true),
            child: Scaffold(
              body: Center(
                child: RevealResultPanel(
                  data: data,
                  nameOpacity: 1,
                  subtitleOpacity: 1,
                  badgeOpacity: 1,
                  buttonOpacity: 1,
                  buttonSlide: 1,
                  continueBusy: busy,
                  continueError: error,
                  onContinue: () => calls++,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      for (var i = 0; i < taps; i++) {
        await tester.tap(find.byType(RevealContinueCta));
        await tester.pump();
      }
      expect(calls, busy ? 0 : taps);
    }

    testWidgets('in-flight disables duplicate taps', (tester) async {
      await pumpPanel(tester, size: const Size(360, 800), busy: true, taps: 3);
      expect(find.byType(RevealContinueCta), findsOneWidget);
    });

    testWidgets('error shows localized retry', (tester) async {
      await pumpPanel(
        tester,
        size: const Size(320, 568),
        busy: false,
        error: ReadingFlowCopy.revealAdvanceFailed,
      );
      expect(find.text(ReadingFlowCopy.revealAdvanceFailed), findsOneWidget);
      expect(find.text(ResilienceCopy.retryAction), findsOneWidget);
      await tester.tap(find.text(ResilienceCopy.retryAction));
      await tester.pump();
    });

    testWidgets('normal viewport success chrome', (tester) async {
      await pumpPanel(tester, size: const Size(390, 844), busy: false);
      expect(find.byType(RevealContinueCta), findsOneWidget);
      expect(find.byType(RevealAdvanceError), findsNothing);
    });
  });

  group('CardRevealScreen Continue', () {
    testWidgets('failure stays on reveal with retry; success navigates once', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final repo = _CountingRepo(
        TarotReadingRepositoryImpl.fromStorage(storage),
      );
      final reading = TarotReadingController(repository: repo);
      addTearDown(reading.dispose);
      final flow = TarotFlowController();
      addTearDown(flow.dispose);

      // Queued multi-card reveal → Continue pushReplaces another reveal
      // (avoids ReadingScreen ProviderScope dependency in this harness).
      await reading.beginSession(
        spread: TarotSpreadType.threeCard,
        deckId: 'classic',
      );
      await reading.advanceToShuffle();
      await reading.performShuffle();
      await reading.finishShuffle();
      await reading.drawAllRemaining();
      final sessionId = reading.session!.id;
      final cardIds = reading.session!.drawnCards
          .map((c) => c.card.id)
          .toList();

      var routes = 0;
      await tester.binding.setSurfaceSize(const Size(360, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        TarotScope(
          flow: flow,
          reading: reading,
          child: MaterialApp(
            theme: AppTheme.dark,
            navigatorObservers: [_CountObserver(() => routes++)],
            home: const MediaQuery(
              data: MediaQueryData(
                size: Size(360, 800),
                disableAnimations: true,
              ),
              child: CardRevealScreen(fromManualPick: true),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      repo.failNextSaves = 1;
      await tester.tap(find.byType(RevealContinueCta));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(ReadingFlowCopy.revealAdvanceFailed), findsOneWidget);
      expect(reading.session!.id, sessionId);
      expect(
        reading.session!.drawnCards.map((c) => c.card.id).toList(),
        cardIds,
      );
      expect(reading.session!.flowStep, ReadingFlowStep.reveal);
      expect(reading.session!.currentPositionIndex, 0);
      final routesAfterFail = routes;

      await tester.tap(find.text(ResilienceCopy.retryAction));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(reading.session!.id, sessionId);
      expect(
        reading.session!.drawnCards.map((c) => c.card.id).toList(),
        cardIds,
      );
      expect(reading.session!.currentPositionIndex, 1);
      expect(routes, greaterThan(routesAfterFail));
      expect(find.text(ReadingFlowCopy.revealAdvanceFailed), findsNothing);
    });

    test('dispose-safe: failed advance restores after await', () async {
      SharedPreferences.setMockInitialValues({});
      final storage = LocalStorage(await SharedPreferences.getInstance());
      final repo = _CountingRepo(
        TarotReadingRepositoryImpl.fromStorage(storage),
      );
      repo.delaySaves = const Duration(milliseconds: 40);
      final reading = TarotReadingController(repository: repo);
      addTearDown(reading.dispose);

      await reading.beginSession(
        spread: TarotSpreadType.threeCard,
        deckId: 'classic',
      );
      await reading.advanceToShuffle();
      await reading.performShuffle();
      await reading.finishShuffle();
      await reading.drawAllRemaining();
      final id = reading.session!.id;
      final position = reading.session!.currentPositionIndex;

      repo.failNextSaves = 1;
      final pending = reading.advanceAfterReveal();
      await expectLater(pending, throwsA(isA<StateError>()));
      expect(reading.session!.id, id);
      expect(reading.session!.currentPositionIndex, position);
      expect(reading.session!.flowStep, ReadingFlowStep.reveal);
    });
  });
}

class _CountingRepo implements TarotReadingRepository {
  _CountingRepo(this._inner);

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

class _CountObserver extends NavigatorObserver {
  _CountObserver(this.onPush);
  final VoidCallback onPush;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => onPush();

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      onPush();
}
