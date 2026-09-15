/// Regression test for the startup warm-up lifecycle defect:
/// `splashScheduleWarmup` used to close over a widget-scoped `WidgetRef`
/// for fire-and-forget work that is expected to keep running after the
/// splash widget itself has been disposed and replaced by Home/Onboarding.
/// Reading through a disposed widget's `ref` throws
/// `Bad state: Cannot use "ref" after the widget was disposed` — previously
/// swallowed as an opaque "[ORACLY] startup notification sync threw: ..."
/// log line instead of being treated as the real lifecycle bug it is.
///
/// The fix drives this work from the app-level `ProviderContainer` instead
/// (captured once, while the widget is still mounted, via
/// `ProviderScope.containerOf(context, listen: false)`), which is not tied
/// to any widget's lifecycle. These tests pin both halves of that
/// contract: a disposed widget's `WidgetRef` really does throw (confirming
/// the original failure mechanism), and the captured `ProviderContainer`
/// keeps working fine after the same disposal.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _probeProvider = Provider<int>((ref) => 7);

class _Probe extends ConsumerStatefulWidget {
  const _Probe({required this.onReady});

  final void Function(WidgetRef ref, ProviderContainer container) onReady;

  @override
  ConsumerState<_Probe> createState() => _ProbeState();
}

class _ProbeState extends ConsumerState<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onReady(ref, ProviderScope.containerOf(context, listen: false));
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

void main() {
  // In the real app, `ProviderScope` wraps the whole app at the root and
  // stays mounted for the entire session — only the splash widget beneath
  // it gets replaced by Home/Onboarding. Both pumps below keep the SAME
  // `ProviderScope`/`MaterialApp` shape mounted (Flutter reuses their
  // Elements across an unkeyed rebuild) and swap only the inner `home`,
  // so the container survives exactly like the real app's root container
  // does, while the leaf widget is genuinely disposed.
  Widget appShell(Widget home) => ProviderScope(child: MaterialApp(home: home));

  testWidgets(
      'a disposed widget\'s WidgetRef throws on read (the original failure '
      'mechanism)', (tester) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      appShell(_Probe(onReady: (ref, container) => capturedRef = ref)),
    );

    // Replace the leaf widget — the splash-equivalent widget is now
    // disposed, exactly like SplashScreen being replaced by Home.
    await tester.pumpWidget(appShell(const SizedBox.shrink()));

    expect(
      () => capturedRef.read(_probeProvider),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('disposed'),
        ),
      ),
    );
  });

  testWidgets(
      'the captured ProviderContainer keeps working after the same '
      'disposal — this is what fire-and-forget warm-up must use', (tester) async {
    late ProviderContainer capturedContainer;
    await tester.pumpWidget(
      appShell(_Probe(onReady: (ref, container) => capturedContainer = container)),
    );

    await tester.pumpWidget(appShell(const SizedBox.shrink()));

    // No "Bad state: ... disposed" — the container outlives the widget.
    expect(capturedContainer.read(_probeProvider), 7);
  });

  testWidgets(
      'splashScheduleWarmup-shaped fire-and-forget work survives disposal '
      'without throwing when driven by the container', (tester) async {
    final events = <String>[];
    late ProviderContainer capturedContainer;

    Future<void> fireAndForgetWarmup(ProviderContainer container) async {
      // Mirrors _runWarmup's shape: an await boundary, then more reads.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      try {
        events.add('read:${container.read(_probeProvider)}');
      } catch (e) {
        events.add('threw:$e');
      }
    }

    await tester.pumpWidget(
      appShell(
        _Probe(
          onReady: (ref, container) {
            capturedContainer = container;
            unawaited(fireAndForgetWarmup(container));
          },
        ),
      ),
    );

    // Dispose the originating widget before the awaited work resolves.
    await tester.pumpWidget(appShell(const SizedBox.shrink()));
    await tester.pump(const Duration(milliseconds: 20));

    expect(events, ['read:7']);
    expect(tester.takeException(), isNull);
    expect(capturedContainer.read(_probeProvider), 7);
  });
}
