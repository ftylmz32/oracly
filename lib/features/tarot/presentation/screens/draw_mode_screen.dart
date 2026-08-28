/// After shuffle — choose how cards leave the real pile.
library;

import 'package:flutter/material.dart';

import '../../../../core/audio/oracly_feedback_gate.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/oracly_reduced_motion.dart';
import '../../../../shared/widgets/oracly_pressable.dart';
import '../../../../shared/widgets/oracly_scaffold.dart';
import '../../copy/tarot_polish_copy.dart';
import '../../domain/models/tarot_spread.dart';
import '../../motion/tarot_cinematic_motion.dart';
import '../../shared/constants/tarot_routes.dart';
import '../../shared/tarot_scope.dart';
import '../../theme/tarot_tokens.dart';
import '../animations/tarot_transition.dart';
import '../widgets/card_selection/card_selection_background.dart';
import '../widgets/draw_mode/draw_mode_option.dart';
import '../widgets/draw_mode/or_draw_focus.dart';
import 'card_reveal_screen.dart';
import 'card_selection_screen.dart';

class DrawModeScreen extends StatefulWidget {
  const DrawModeScreen({super.key});

  @override
  State<DrawModeScreen> createState() => _DrawModeScreenState();
}

class _DrawModeScreenState extends State<DrawModeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _focus;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _focus = AnimationController(
      vsync: this,
      duration: TarotCinematicMotion.draw,
    );
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  Future<void> _chooseManual() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      TarotScope.of(context).flow.selectDrawMode(TarotDrawMode.manual);
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      cardSelectionRitualRoute<void>(
        page: const CardSelectionScreen(),
        settings: const RouteSettings(name: TarotRoutes.cardSelection),
      ),
    );
  }

  Future<void> _chooseOr() async {
    if (_busy) return;
    setState(() => _busy = true);
    TarotScope.of(context).flow.selectDrawMode(TarotDrawMode.orDraw);
    OraclyTouchFeedback.selection();
    OraclyFeedbackGate.cardMove();
    if (!OraclyReducedMotion.of(context)) {
      await _focus.forward();
    } else {
      _focus.value = 1;
    }
    if (!mounted) return;
    try {
      await TarotScope.of(context).reading.drawAllRemaining();
    } catch (_) {
      if (!mounted) return;
      _focus.value = 0;
      setState(() => _busy = false);
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      cardRevealRitualRoute<void>(
        page: const CardRevealScreen(),
        settings: const RouteSettings(name: TarotRoutes.cardReveal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return OraclyScaffold(
      backgroundOverlay: const CardSelectionBackground(),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: TarotTokens.screenPaddingOf(context),
          child: AnimatedBuilder(
            animation: _focus,
            builder: (context, child) {
              final focus = _focus.value.clamp(0.0, 1.0);
              return Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: (1 - focus * 0.92).clamp(0.0, 1.0),
                    child: IgnorePointer(ignoring: _busy, child: child),
                  ),
                  OrDrawFocus(progress: focus),
                  Positioned.fill(
                    child: OrDrawGoldHaze(progress: focus),
                  ),
                ],
              );
            },
            child: Column(
              children: [
                const Spacer(),
                DrawModeOption(
                  title: TarotPolishCopy.drawOr,
                  blurb: TarotPolishCopy.drawOrBlurb,
                  emphasized: true,
                  onTap: _chooseOr,
                ),
                const SizedBox(height: AppSpacing.md),
                DrawModeOption(
                  title: TarotPolishCopy.drawManual,
                  blurb: TarotPolishCopy.drawManualBlurb,
                  onTap: _chooseManual,
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Route<T> drawModeRitualRoute<T>({
  required Widget page,
  RouteSettings? settings,
}) {
  return tarotRitualDepthHandoffRoute<T>(
    page: page,
    settings: settings,
    scaleBegin: TarotTokens.handoffScaleSelectionBegin,
  );
}
