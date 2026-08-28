/// P1 — Performance release pass (TECNO KN8 / QuietMotion).
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oracly_new/core/theme/oracly_quiet_motion.dart';
import 'package:oracly_new/core/theme/oracly_soft_glow.dart';
import 'package:oracly_new/features/tarot/motion/tarot_ambient_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tarotSyncAmbient freezes on KN8-class metrics', (tester) async {
    late AnimationController controller;
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(size: Size(360, 800), devicePixelRatio: 2.0),
        child: _TarotAmbientProbe(),
      ),
    );
    await tester.pump();
    final state =
        tester.state<_TarotAmbientProbeState>(find.byType(_TarotAmbientProbe));
    controller = state.controller;
    expect(OraclyQuietMotion.constrained(state.context), isTrue);
    expect(controller.isAnimating, isFalse);
    expect(controller.value, 0.5);
  });

  testWidgets('soft glow skips ImageFiltered on constrained devices', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(size: Size(360, 800), devicePixelRatio: 2.0),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: OraclySoftGlow(
            width: 120,
            height: 120,
            color: Color(0x66FFFFFF),
            sigma: 72,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.byType(DecoratedBox), findsWidgets);
  });

  testWidgets('soft glow keeps ImageFiltered on high-end metrics', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(size: Size(430, 932), devicePixelRatio: 3.0),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: OraclySoftGlow(
            width: 120,
            height: 120,
            color: Color(0x66FFFFFF),
            sigma: 72,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(OraclyQuietMotion.constrained(
      tester.element(find.byType(OraclySoftGlow)),
    ), isFalse);
    expect(find.byType(ImageFiltered), findsOneWidget);
  });
}

class _TarotAmbientProbe extends StatefulWidget {
  const _TarotAmbientProbe();

  @override
  State<_TarotAmbientProbe> createState() => _TarotAmbientProbeState();
}

class _TarotAmbientProbeState extends State<_TarotAmbientProbe>
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
    tarotSyncAmbient(context, controller, reverse: true);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
