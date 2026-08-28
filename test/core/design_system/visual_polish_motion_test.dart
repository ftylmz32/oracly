/// Phase 7 — reduced motion, quiet fallback, no bounce.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/design_system/app_motion.dart';
import 'package:oracly_new/core/design_system/oracly_soft_reveal.dart';
import 'package:oracly_new/core/theme/oracly_quiet_motion.dart';
import 'package:oracly_new/core/theme/oracly_reduced_motion.dart';

void main() {
  testWidgets('reduced motion collapses duration to zero', (tester) async {
    late BuildContext captured;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: Builder(
          builder: (context) {
            captured = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(OraclyReducedMotion.of(captured), isTrue);
    expect(
      OraclyReducedMotion.duration(captured, const Duration(milliseconds: 400)),
      Duration.zero,
    );
  });

  testWidgets('soft reveal shows child immediately when motion reduced',
      (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: OraclySoftReveal(child: Text('polished')),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('polished'), findsOneWidget);
  });

  test('shared spring is a settle, not a bounce', () {
    expect(AppMotionCurve.spring, Curves.easeOutCubic);
    expect(AppMotionCurve.spring.transform(0.5), lessThan(1));
  });

  testWidgets('720p-class devices freeze ambient loops', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(360, 800),
          devicePixelRatio: 2.0,
        ),
        child: _AmbientProbe(),
      ),
    );
    await tester.pump();
    final state = tester.state<_AmbientProbeState>(find.byType(_AmbientProbe));
    expect(state.controller.isAnimating, isFalse);
    expect(state.controller.value, 0.5);
  });

  testWidgets('mid-range HD+ phones freeze ambient loops', (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(360, 800),
          devicePixelRatio: 2.5,
        ),
        child: _AmbientProbe(),
      ),
    );
    await tester.pump();
    final state = tester.state<_AmbientProbeState>(find.byType(_AmbientProbe));
    expect(OraclyQuietMotion.constrained(state.context), isTrue);
    expect(state.controller.isAnimating, isFalse);
  });

  testWidgets('reduce-motion freezes ambient even on high-end metrics',
      (tester) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(
          size: Size(430, 932),
          devicePixelRatio: 3.0,
          disableAnimations: true,
        ),
        child: _AmbientProbe(),
      ),
    );
    await tester.pump();
    final state = tester.state<_AmbientProbeState>(find.byType(_AmbientProbe));
    expect(state.controller.isAnimating, isFalse);
  });
}

class _AmbientProbe extends StatefulWidget {
  const _AmbientProbe();

  @override
  State<_AmbientProbe> createState() => _AmbientProbeState();
}

class _AmbientProbeState extends State<_AmbientProbe>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    OraclyQuietMotion.ambient(context, controller, reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
