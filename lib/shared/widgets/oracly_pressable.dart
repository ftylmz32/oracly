/// TASK-002 — Canonical touch feedback for every Oracly interaction.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/oracly_brand_signature.dart';
import '../../core/theme/oracly_reduced_motion.dart';
import '../../core/audio/oracly_feedback_gate.dart';

/// Quiet press acknowledgement — scale, opacity, depth, optional glow shift.
///
/// All tappable surfaces should feel like the same material: soft, confident,
/// never springy or game-like.
class OraclyPressable extends StatefulWidget {
  const OraclyPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.enabled = true,
    this.behavior = HitTestBehavior.deferToChild,
    this.haptic = true,
    /// Soft ritual tap SFX — off by default (never spam every surface).
    this.softSound = false,
    this.scale = true,
    this.opacity = true,
    this.depth = true,
    this.glowShift = false,
    this.borderRadius,
    this.label,
  });

  final Widget child;
  final VoidCallback? onTap;
  final GestureTapDownCallback? onTapDown;
  final GestureTapUpCallback? onTapUp;
  final GestureTapCancelCallback? onTapCancel;
  final bool enabled;
  final HitTestBehavior behavior;
  final bool haptic;
  final bool softSound;
  final bool scale;
  final bool opacity;
  final bool depth;
  final bool glowShift;
  final BorderRadius? borderRadius;
  /// Screen-reader / tooltip meaning when the child has no visible text.
  final String? label;

  @override
  State<OraclyPressable> createState() => _OraclyPressableState();
}

class _OraclyPressableState extends State<OraclyPressable> {
  bool _pressed = false;

  bool get _interactive => widget.enabled && widget.onTap != null;

  Duration get _duration => _pressed
      ? OraclySignatureMotion.press
      : OraclySignatureMotion.pressRelease;

  Curve get _curve =>
      _pressed ? OraclySignatureMotion.curve : OraclySignatureMotion.releaseCurve;

  Duration _motionDuration(BuildContext context) =>
      OraclyReducedMotion.duration(context, _duration);

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTapDown(TapDownDetails details) {
    if (!_interactive) return;
    _setPressed(true);
    widget.onTapDown?.call(details);
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_interactive) return;
    _setPressed(false);
    widget.onTapUp?.call(details);
  }

  void _handleTapCancel() {
    if (!_interactive) return;
    _setPressed(false);
    widget.onTapCancel?.call();
  }

  void _handleTap() {
    if (!_interactive) return;
    if (widget.haptic) {
      OraclyTouchFeedback.acknowledge();
    }
    if (widget.softSound) {
      OraclyFeedbackGate.softTap();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_interactive) return widget.child;

    final pressed = _pressed;
    final motion = _motionDuration(context);
    final scaleValue =
        widget.scale && pressed ? OraclySignatureMotion.pressScale : 1.0;
    final opacityValue =
        widget.opacity && pressed ? OraclySignatureMotion.pressOpacity : 1.0;
    final depthValue =
        widget.depth && pressed ? OraclySignatureMotion.pressDepth : 0.0;

    Widget body = widget.child;

    if (widget.glowShift) {
      body = AnimatedContainer(
        duration: motion,
        curve: _curve,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: pressed ? 0.24 : 0.18),
              blurRadius: pressed ? 10 : 14,
              offset: Offset(0, pressed ? 2 : 4),
            ),
          ],
        ),
        child: body,
      );
    }

    body = AnimatedOpacity(
      opacity: opacityValue,
      duration: motion,
      curve: _curve,
      child: body,
    );

    body = AnimatedScale(
      scale: scaleValue,
      duration: motion,
      curve: _curve,
      alignment: Alignment.center,
      child: body,
    );

    body = AnimatedContainer(
      duration: motion,
      curve: _curve,
      transform: Matrix4.translationValues(0, depthValue, 0),
      child: body,
    );

    return FocusableActionDetector(
      enabled: _interactive,
      mouseCursor: SystemMouseCursors.click,
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            _handleTap();
            return null;
          },
        ),
      },
      child: Semantics(
        button: true,
        enabled: widget.enabled,
        label: widget.label,
        child: GestureDetector(
          behavior: widget.behavior,
          onTapDown: _handleTapDown,
          onTapUp: _handleTapUp,
          onTapCancel: _handleTapCancel,
          onTap: _handleTap,
          child: body,
        ),
      ),
    );
  }
}

/// Shared haptic — one quiet acknowledgement, never celebratory.
abstract final class OraclyTouchFeedback {
  OraclyTouchFeedback._();

  static void acknowledge() {
    if (!OraclyFeedbackGate.hapticEnabled) return;
    HapticFeedback.lightImpact();
  }

  static void selection() {
    if (!OraclyFeedbackGate.hapticEnabled) return;
    HapticFeedback.selectionClick();
  }

  /// Soft reveal — never medium or heavy.
  static void reveal() {
    if (!OraclyFeedbackGate.hapticEnabled) return;
    HapticFeedback.lightImpact();
  }
}
