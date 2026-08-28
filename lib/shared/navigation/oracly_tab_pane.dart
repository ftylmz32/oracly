/// One tab pane — same universe room crossfade; keep navigator + scroll state.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/navigation/immersive/chamber_transition_personality.dart';
import '../../core/navigation/immersive/immersive_motion.dart';
import '../../core/theme/oracly_reduced_motion.dart';
import 'oracly_tab_navigator.dart';

class OraclyTabPane extends StatefulWidget {
  const OraclyTabPane({
    super.key,
    required this.active,
    required this.navigatorKey,
    required this.root,
    this.personality = ChamberTransitionPersonality.chamber,
  });

  final bool active;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget root;
  final ChamberTransitionPersonality personality;

  @override
  State<OraclyTabPane> createState() => _OraclyTabPaneState();
}

class _OraclyTabPaneState extends State<OraclyTabPane> {
  late bool _staged = widget.active;
  Timer? _hide;

  @override
  void didUpdateWidget(OraclyTabPane oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active) {
      _hide?.cancel();
      if (!_staged) setState(() => _staged = true);
      return;
    }
    if (!oldWidget.active) return;
    _hide?.cancel();
    final tokens = ChamberTransitionTokens.of(widget.personality);
    final duration = OraclyReducedMotion.duration(context, tokens.exit);
    _hide = Timer(duration, () {
      if (!mounted || widget.active) return;
      setState(() => _staged = false);
    });
  }

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = ChamberTransitionTokens.of(widget.personality);
    final duration = OraclyReducedMotion.duration(
      context,
      widget.active ? tokens.enter : tokens.exit,
    );
    final curve = ImmersiveMotion.pageEnterCurve;

    return TickerMode(
      // Keep tickers while staged so exit fade can finish; pause when offstage.
      enabled: widget.active || _staged,
      child: Offstage(
        offstage: !_staged,
        child: RepaintBoundary(
          child: IgnorePointer(
            ignoring: !widget.active,
            child: AnimatedOpacity(
              opacity: widget.active ? 1 : 0,
              duration: duration,
              curve: curve,
              child: AnimatedScale(
                scale: widget.active ? 1 : tokens.scaleBegin,
                duration: duration,
                curve: curve,
                alignment: Alignment.topCenter,
                child: AnimatedSlide(
                  offset: widget.active
                      ? Offset.zero
                      : Offset(0, tokens.slideFraction),
                  duration: duration,
                  curve: curve,
                  child: OraclyTabNavigator(
                    navigatorKey: widget.navigatorKey,
                    root: widget.root,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
