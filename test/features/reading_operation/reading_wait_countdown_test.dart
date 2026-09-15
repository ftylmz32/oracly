/// Coffee/Palm waiting screen -- countdown must be driven purely by the
/// server-synced snapshot (readyAt/serverNow) plus monotonic elapsed time,
/// never by device wall clock, and must resync cleanly on every fresh
/// snapshot (background/resume, restart, acceleration).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_snapshot.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/presentation/reading_wait_countdown_clock.dart';
import 'package:oracly_new/features/reading_operation/presentation/reading_wait_countdown_face.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';

ReadingOperationSnapshot _snapshot({
  required DateTime serverNow,
  required DateTime readyAt,
  String operationId = 'op-1',
}) {
  return ReadingOperationSnapshot(
    operationId: operationId,
    readingType: ReadingType.coffee,
    status: ReadingOperationStatus.waiting,
    createdAt: serverNow,
    readyAt: readyAt,
    serverNow: serverNow,
    waitFinished: false,
    remainingMs: readyAt.difference(serverNow).inMilliseconds,
    resultReady: false,
    resultId: null,
  );
}

ReadingLiveState _waiting(ReadingOperationSnapshot snap) =>
    ReadingLiveState(kind: ReadingLiveKind.waiting, snapshot: snap);

/// Reads the currently-displayed two-digit value for one countdown unit
/// (hours/minutes/seconds), found by its semantics label rather than an
/// exact digit string -- a real, tiny amount of wall-clock time always
/// passes between starting the stopwatch and the first read, so asserting
/// an exact digit at t=0 would be flaky by a fraction of a second.
int _unitValue(WidgetTester tester, String unitLabel) {
  final pattern = RegExp('^[0-9]+ $unitLabel\$');
  final finder = find.byWidgetPredicate(
    (w) => w is Text && pattern.hasMatch(w.semanticsLabel ?? ''),
  );
  expect(finder, findsOneWidget, reason: 'no $unitLabel unit found');
  return int.parse(tester.widget<Text>(finder).data!);
}

Future<void> _pumpClock(
  WidgetTester tester,
  ReadingLiveState? state, {
  Size size = const Size(390, 844),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: ReadingWaitCountdownClock(liveState: state),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  testWidgets('ticks down correctly, one second at a time', (tester) async {
    // The clock deliberately uses a real Stopwatch (monotonic, immune to
    // device-clock changes) rather than Timer-driven fake time, so
    // verifying real per-second ticking needs runAsync to let real time
    // and real timers actually advance together, exactly as in production.
    await tester.runAsync(() async {
      final now = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final state = _waiting(
        _snapshot(serverNow: now, readyAt: now.add(const Duration(seconds: 5))),
      );
      await _pumpClock(tester, state);
      final start = _unitValue(tester, 'saniye');
      expect(start, anyOf(4, 5));
      await Future<void>.delayed(const Duration(milliseconds: 1050));
      await tester.pump();
      expect(_unitValue(tester, 'saniye'), start - 1);
      await Future<void>.delayed(const Duration(milliseconds: 1050));
      await tester.pump();
      expect(_unitValue(tester, 'saniye'), start - 2);
    });
  });

  testWidgets('uses the server snapshot, not device wall clock', (
    tester,
  ) async {
    // serverNow is already "in the past" relative to whatever the test
    // device clock says -- if the widget consulted DateTime.now() it would
    // compute a wildly different (or full) remaining duration. It must not.
    final serverNow = DateTime.utc(2020, 1, 1);
    final readyAt = serverNow.add(const Duration(minutes: 2, seconds: 3));
    final state = _waiting(_snapshot(serverNow: serverNow, readyAt: readyAt));
    await _pumpClock(tester, state);
    expect(_unitValue(tester, 'dakika'), 2);
    expect(_unitValue(tester, 'saniye'), anyOf(2, 3));
  });

  testWidgets('a fresh snapshot resyncs the countdown immediately (background/resume/restart)', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 1, 1);
    final state = _waiting(
      _snapshot(serverNow: now, readyAt: now.add(const Duration(seconds: 30))),
    );
    await _pumpClock(tester, state);
    await tester.pump(const Duration(seconds: 10));
    // ~20s left at this point (30 - 10).

    // Simulate the app coming back (background/resume, or a full restart
    // that re-fetched the operation) with a genuinely fresh server sync --
    // remaining must jump to reflect that fresh truth, not continue
    // counting from the stale local trajectory and not reset to the full
    // original duration either.
    final resumedAt = DateTime.utc(2026, 1, 1, 0, 0, 5);
    final resynced = _waiting(
      _snapshot(
        serverNow: resumedAt,
        readyAt: now.add(const Duration(seconds: 30)),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ReadingWaitCountdownClock(liveState: resynced)),
      ),
    );
    await tester.pump();
    // readyAt - serverNow = 30s - 5s = 25s remaining -- not the stale ~20s
    // trajectory and not a reset to a full duration unrelated to readyAt.
    expect(_unitValue(tester, 'saniye'), anyOf(24, 25));
  });

  testWidgets('reaches zero cleanly and never goes negative', (tester) async {
    // Same real-Stopwatch reasoning as the ticking test above: a fake
    // tester.pump(duration) does not itself advance real elapsed time, so
    // real time must actually pass for the countdown to genuinely reach and
    // hold zero.
    await tester.runAsync(() async {
      final now = DateTime.utc(2026, 1, 1);
      final state = _waiting(
        _snapshot(serverNow: now, readyAt: now.add(const Duration(seconds: 1))),
      );
      await _pumpClock(tester, state);
      await Future<void>.delayed(const Duration(milliseconds: 2500));
      await tester.pump();
      expect(_unitValue(tester, 'saniye'), 0);
      expect(_unitValue(tester, 'dakika'), 0);
      expect(_unitValue(tester, 'saat'), 0);
      expect(find.textContaining('-'), findsNothing);
      // Stays at zero -- never goes negative as more real time passes.
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      await tester.pump();
      expect(_unitValue(tester, 'saniye'), 0);
    });
  });

  testWidgets('a null live state shows 00:00:00, not an error', (
    tester,
  ) async {
    await _pumpClock(tester, null);
    expect(find.text('00'), findsNWidgets(3));
  });

  group('ReadingWaitCountdownFace at required viewport widths', () {
    for (final size in [
      Size(320, 568),
      Size(360, 800),
      Size(390, 844),
    ]) {
      testWidgets('renders 12h05m09s without overflow at ${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: size),
              child: const Scaffold(
                body: Center(
                  child: ReadingWaitCountdownFace(
                    remaining: Duration(hours: 12, minutes: 5, seconds: 9),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('12'), findsOneWidget);
        expect(find.text('05'), findsOneWidget);
        expect(find.text('09'), findsOneWidget);
      });
    }
  });
}
