/// Coffee/Palm shared waiting screen -- CTA wiring, error banner, disabled
/// rewarded-video row, and layout at the required small-device widths.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/l10n/l10n.dart';
import 'package:oracly_new/features/reading_operation/copy/reading_live_copy.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_snapshot.dart';
import 'package:oracly_new/features/reading_operation/models/reading_operation_status.dart';
import 'package:oracly_new/features/reading_operation/presentation/reading_wait_screen.dart';
import 'package:oracly_new/features/reading_operation/services/reading_live_flow.dart';

Future<void> _pumpScreen(
  WidgetTester tester, {
  Size size = const Size(390, 844),
  VoidCallback? onAccelerate,
  bool accelerating = false,
  String? accelerationError,
  ReadingLiveState? liveState,
  int? accelerationCost,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: ReadingWaitScreen(
            liveState: liveState,
            onAccelerate: onAccelerate,
            accelerating: accelerating,
            accelerationError: accelerationError,
            accelerationCost: accelerationCost,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

ReadingLiveState _waitingState({required Duration remaining}) {
  final now = DateTime.utc(2026, 1, 1, 12);
  return ReadingLiveState(
    kind: ReadingLiveKind.waiting,
    snapshot: ReadingOperationSnapshot(
      operationId: '0' * 32,
      readingType: ReadingType.coffee,
      status: ReadingOperationStatus.waiting,
      createdAt: now,
      readyAt: now.add(remaining),
      serverNow: now,
      waitFinished: remaining <= Duration.zero,
      remainingMs: remaining.inMilliseconds,
      resultReady: false,
      resultId: null,
    ),
  );
}

ReadingLiveState _processingState() {
  final now = DateTime.utc(2026, 1, 1, 12);
  return ReadingLiveState(
    kind: ReadingLiveKind.processing,
    snapshot: ReadingOperationSnapshot(
      operationId: '0' * 32,
      readingType: ReadingType.coffee,
      status: ReadingOperationStatus.processing,
      createdAt: now,
      readyAt: now,
      serverNow: now,
      waitFinished: true,
      remainingMs: 0,
      resultReady: false,
      resultId: null,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => OraclyL10n.bind('tr'));

  testWidgets('shows the required headline, subtitle, and background info copy', (
    tester,
  ) async {
    await _pumpScreen(tester);
    expect(find.text(ReadingLiveCopy.headline), findsOneWidget);
    expect(find.text(ReadingLiveCopy.subtitle), findsOneWidget);
    expect(find.text(ReadingLiveCopy.backgroundInfo), findsOneWidget);
  });

  testWidgets('tapping the accelerate CTA invokes onAccelerate exactly once', (
    tester,
  ) async {
    var calls = 0;
    await _pumpScreen(tester, onAccelerate: () => calls++);
    expect(find.text(ReadingLiveCopy.accelerateCta), findsOneWidget);
    await tester.tap(find.text(ReadingLiveCopy.accelerateCta));
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets('while accelerating, the CTA is disabled and shows a processing label', (
    tester,
  ) async {
    var calls = 0;
    await _pumpScreen(
      tester,
      onAccelerate: () => calls++,
      accelerating: true,
    );
    expect(find.text(ReadingLiveCopy.accelerateCta), findsNothing);
    expect(find.text(ReadingLiveCopy.processing), findsOneWidget);
    // Real button hit-testing (not just checking onPressed==null) --
    // rapid re-taps while accelerating must not queue up extra calls.
    await tester.tap(find.text(ReadingLiveCopy.processing), warnIfMissed: false);
    await tester.tap(find.text(ReadingLiveCopy.processing), warnIfMissed: false);
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets('an acceleration error shows a visible, non-blocking banner', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      onAccelerate: () {},
      accelerationError: ReadingLiveCopy.insufficient,
    );
    expect(find.text(ReadingLiveCopy.insufficient), findsOneWidget);
    // CTA remains usable -- an error must not itself strand the user.
    expect(find.text(ReadingLiveCopy.accelerateCta), findsOneWidget);
  });

  testWidgets('with no onAccelerate at all, no error banner, the screen still renders cleanly', (
    tester,
  ) async {
    await _pumpScreen(tester);
    expect(tester.takeException(), isNull);
  });

  group('no overflow at required small-device widths', () {
    for (final size in [Size(320, 568), Size(360, 800), Size(390, 844)]) {
      testWidgets('${size.width.toInt()}x${size.height.toInt()}', (
        tester,
      ) async {
        await _pumpScreen(
          tester,
          size: size,
          onAccelerate: () {},
          accelerationError: ReadingLiveCopy.insufficient,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('the Gem CTA never appears once the free wait is already over', () {
    testWidgets('countdown > 0 shows the CTA', (tester) async {
      await _pumpScreen(
        tester,
        onAccelerate: () {},
        liveState: _waitingState(remaining: const Duration(seconds: 30)),
        accelerationCost: 10,
      );
      expect(find.text(ReadingLiveCopy.accelerateCtaWithCost(10)), findsOneWidget);
      expect(find.text(ReadingLiveCopy.overdueWaiting), findsNothing);
    });

    testWidgets('countdown reaching 0 hides the CTA and shows the neutral overdue copy', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        onAccelerate: () {},
        liveState: _waitingState(remaining: Duration.zero),
        accelerationCost: 10,
      );
      expect(find.text(ReadingLiveCopy.accelerateCtaWithCost(10)), findsNothing);
      expect(find.text(ReadingLiveCopy.accelerateCta), findsNothing);
      expect(find.text(ReadingLiveCopy.overdueWaiting), findsOneWidget);
    });

    testWidgets('past readyAt (negative remaining) also hides the CTA -- never a device-clock guess, same server-synced snapshot', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        onAccelerate: () {},
        liveState: _waitingState(remaining: const Duration(seconds: -45)),
        accelerationCost: 10,
      );
      expect(find.text(ReadingLiveCopy.accelerateCtaWithCost(10)), findsNothing);
      expect(find.text(ReadingLiveCopy.overdueWaiting), findsOneWidget);
    });

    testWidgets('a delayed server claim (processing) still shows no CTA -- it never reappears', (
      tester,
    ) async {
      await _pumpScreen(
        tester,
        onAccelerate: () {},
        liveState: _processingState(),
        accelerationCost: 10,
      );
      expect(find.text(ReadingLiveCopy.accelerateCtaWithCost(10)), findsNothing);
      expect(find.text(ReadingLiveCopy.accelerateCta), findsNothing);
      expect(find.text(ReadingLiveCopy.processingDetail), findsOneWidget);
    });

    testWidgets('a restarted app observing an already-overdue operation shows no CTA either', (
      tester,
    ) async {
      // Simulates recoverActive() handing the widget a freshly-recovered
      // snapshot after a cold restart -- same overdue state, same rule.
      await _pumpScreen(
        tester,
        onAccelerate: () {},
        liveState: _waitingState(remaining: const Duration(seconds: -5)),
        accelerationCost: 10,
      );
      expect(find.text(ReadingLiveCopy.accelerateCtaWithCost(10)), findsNothing);
      expect(find.text(ReadingLiveCopy.overdueWaiting), findsOneWidget);
    });
  });
}
