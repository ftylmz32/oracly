/// OR-301+ — Elastic scroll with soft overscroll glow.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// Gentle bounce for a premium scroll feel.
class ReadingScrollPhysics extends BouncingScrollPhysics {
  const ReadingScrollPhysics({super.parent});

  @override
  ReadingScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ReadingScrollPhysics(parent: buildParent(ancestor));
  }
}

class ReadingPremiumScrollView extends StatefulWidget {
  const ReadingPremiumScrollView({
    super.key,
    required this.child,
    this.padding,
    this.physics,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  @override
  State<ReadingPremiumScrollView> createState() =>
      _ReadingPremiumScrollViewState();
}

class _ReadingPremiumScrollViewState extends State<ReadingPremiumScrollView> {
  final ValueNotifier<double> _topGlow = ValueNotifier(0);
  final ValueNotifier<double> _bottomGlow = ValueNotifier(0);

  @override
  void dispose() {
    _topGlow.dispose();
    _bottomGlow.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;

    final pixels = notification.metrics.pixels;
    final max = notification.metrics.maxScrollExtent;
    var top = 0.0;
    var bottom = 0.0;

    if (pixels < 0) {
      top = (-pixels / 80).clamp(0.0, 1.0);
    }
    if (pixels > max) {
      bottom = ((pixels - max) / 80).clamp(0.0, 1.0);
    }

    if ((top - _topGlow.value).abs() > 0.01) {
      _topGlow.value = top;
    }
    if ((bottom - _bottomGlow.value).abs() > 0.01) {
      _bottomGlow.value = bottom;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            physics: widget.physics ??
                const ReadingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
            padding: widget.padding,
            child: widget.child,
          ),
          ListenableBuilder(
            listenable: Listenable.merge([_topGlow, _bottomGlow]),
            builder: (context, _) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  _OverscrollGlow(intensity: _topGlow.value, top: true),
                  _OverscrollGlow(intensity: _bottomGlow.value, top: false),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _OverscrollGlow extends StatelessWidget {
  const _OverscrollGlow({required this.intensity, required this.top});

  final double intensity;
  final bool top;

  @override
  Widget build(BuildContext context) {
    if (intensity < 0.02) return const SizedBox.shrink();

    return IgnorePointer(
      child: Align(
        alignment: top ? Alignment.topCenter : Alignment.bottomCenter,
        child: Container(
          height: 72,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: top ? Alignment.topCenter : Alignment.bottomCenter,
              end: top ? Alignment.bottomCenter : Alignment.topCenter,
              colors: [
                AppColors.purple.withValues(alpha: 0.14 * intensity),
                AppColors.gold.withValues(alpha: 0.06 * intensity),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Ambient phase helper for subtle overscroll-independent motion.
double readingScrollAmbientPhase(double controllerValue) =>
    sin(controllerValue * pi * 2) * 0.5 + 0.5;
