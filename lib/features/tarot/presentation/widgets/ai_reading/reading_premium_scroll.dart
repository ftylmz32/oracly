/// OR-301+ — Elastic scroll with soft overscroll glow.
library;

import 'dart:math' show pi, sin;

import 'package:flutter/material.dart';

import '../../../../../core/reading_ux/reading_sticky_kicker.dart';
import '../../../../../core/theme/app_colors.dart';

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
    this.kicker,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final String? kicker;

  @override
  State<ReadingPremiumScrollView> createState() =>
      _ReadingPremiumScrollViewState();
}

class _ReadingPremiumScrollViewState extends State<ReadingPremiumScrollView> {
  final ValueNotifier<double> _topGlow = ValueNotifier(0);
  final ValueNotifier<double> _bottomGlow = ValueNotifier(0);
  final ValueNotifier<double> _pixels = ValueNotifier(0);

  @override
  void dispose() {
    _topGlow.dispose();
    _bottomGlow.dispose();
    _pixels.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final pixels = notification.metrics.pixels;
    final max = notification.metrics.maxScrollExtent;
    _pixels.value = pixels;
    final top = pixels < 0 ? (-pixels / 80).clamp(0.0, 1.0) : 0.0;
    final bottom = pixels > max ? ((pixels - max) / 80).clamp(0.0, 1.0) : 0.0;
    if ((top - _topGlow.value).abs() > 0.01) _topGlow.value = top;
    if ((bottom - _bottomGlow.value).abs() > 0.01) _bottomGlow.value = bottom;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final kicker = widget.kicker?.trim() ?? '';
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
          if (kicker.isNotEmpty)
            ListenableBuilder(
              listenable: _pixels,
              builder: (context, _) {
                if (_pixels.value < 56) return const SizedBox.shrink();
                return Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ReadingStickyKicker(title: kicker),
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

double readingScrollAmbientPhase(double controllerValue) =>
    sin(controllerValue * pi * 2) * 0.5 + 0.5;
