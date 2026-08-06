/// OR-412 — Emotional gravity & premium focus system.
library;

import 'package:flutter/material.dart';

import 'home_composition.dart';
import 'home_atmosphere.dart';
import 'home_architecture.dart';
import 'home_observatory.dart';
import 'home_presence.dart';
import 'home_reward.dart';

/// Primary · secondary · tertiary hierarchy for emotional focus.
enum HomeFocusTier {
  primary,
  secondary,
  tertiary,
}

/// Interactive and ambient zones on the home composition.
enum HomeFocusZone {
  none,
  header,
  orb,
  spread,
  daily,
  premium,
  ai,
  cosmic,
}

/// Focus math — light, contrast, depth, glow, motion. Never size.
abstract final class HomeFocus {
  HomeFocus._();

  static const transition = Duration(milliseconds: 340);
  static const curve = Curves.easeOutCubic;

  static HomeFocusTier tierFor(HomeFocusZone zone) => switch (zone) {
        HomeFocusZone.orb => HomeFocusTier.primary,
        HomeFocusZone.spread ||
        HomeFocusZone.daily ||
        HomeFocusZone.premium ||
        HomeFocusZone.ai =>
          HomeFocusTier.secondary,
        HomeFocusZone.header ||
        HomeFocusZone.cosmic ||
        HomeFocusZone.none =>
          HomeFocusTier.tertiary,
      };

  static HomeFocusZone zoneForBand(HomeCompositionBand band) =>
      switch (band) {
        HomeCompositionBand.explore => HomeFocusZone.spread,
        HomeCompositionBand.reflect => HomeFocusZone.ai,
        HomeCompositionBand.understand => HomeFocusZone.cosmic,
      };

  /// Resting opacity — orb leads, support whispers.
  static double restingOpacity(HomeFocusZone zone) =>
      (switch (tierFor(zone)) {
        HomeFocusTier.primary => 1.0,
        HomeFocusTier.secondary => 0.94,
        HomeFocusTier.tertiary => 0.82,
      }) *
      HomeAtmosphere.orbAnchorWeight(zone);

  /// Glow emphasis — orb hope; nothing challenges the anchor.
  static double glow({
    required HomeFocusZone zone,
    required HomeFocusZone active,
  }) {
    if (active == HomeFocusZone.none) {
      final base = switch (tierFor(zone)) {
        HomeFocusTier.primary => 1.14,
        HomeFocusTier.secondary => 0.86,
        HomeFocusTier.tertiary => 0.56,
      };
      return base * HomeAtmosphere.orbAnchorWeight(zone);
    }
    if (zone == active) return 1.18;
    return switch (tierFor(zone)) {
      HomeFocusTier.primary => 0.76,
      HomeFocusTier.secondary => 0.66,
      HomeFocusTier.tertiary => 0.46,
    };
  }

  /// Opacity for a zone given where attention currently lives.
  static double opacity({
    required HomeFocusZone zone,
    required HomeFocusZone active,
  }) {
    if (active == HomeFocusZone.none) return restingOpacity(zone);
    if (zone == active) return 1.0;
    final rest = restingOpacity(zone);
    final drop = switch (tierFor(zone)) {
      HomeFocusTier.primary => 0.08,
      HomeFocusTier.secondary => 0.12,
      HomeFocusTier.tertiary => 0.16,
    };
    return (rest - drop).clamp(0.72, 1.0);
  }

  /// Motion channel — only the active interaction breathes fully.
  static double motion({
    required HomeFocusZone zone,
    required HomeFocusZone active,
  }) {
    if (active == HomeFocusZone.none) {
      return zone == HomeFocusZone.orb ? 1.0 : 0.72;
    }
    if (zone == active) return 1.0;
    return switch (tierFor(zone)) {
      HomeFocusTier.primary => 0.48,
      HomeFocusTier.secondary => 0.38,
      HomeFocusTier.tertiary => 0.28,
    };
  }

  /// Background / particle calm factor.
  static double ambientCalm(HomeFocusZone active) =>
      active == HomeFocusZone.none ? 1.0 : 0.62;

  /// Soft contrast matrix — peaceful darks, hopeful lights.
  static List<double> contrastMatrix(double emphasis) =>
      HomeAtmosphere.softContrastMatrix(emphasis);

  /// Impeller-safe emphasis — contrast + opacity without [Opacity] widget.
  static List<double> visualMatrix({
    required double contrast,
    required double opacity,
  }) {
    final c = 0.88 + contrast * 0.10;
    final t = (1 - c) * 128;
    final o = opacity.clamp(0.0, 1.0);
    return <double>[
      c, 0, 0, 0, t,
      0, c, 0, 0, t,
      0, 0, c, 0, t,
      0, 0, 0, o, 0,
    ];
  }

  static double contrastEmphasis({
    required HomeFocusZone zone,
    required HomeFocusZone active,
  }) {
    if (active == HomeFocusZone.none) {
      return switch (tierFor(zone)) {
        HomeFocusTier.primary => 1.0,
        HomeFocusTier.secondary => 0.94,
        HomeFocusTier.tertiary => 0.88,
      };
    }
    if (zone == active) return 1.0;
    return switch (tierFor(zone)) {
      HomeFocusTier.primary => 0.86,
      HomeFocusTier.secondary => 0.82,
      HomeFocusTier.tertiary => 0.78,
    };
  }
}

/// Inherited focus state — no providers, local to the home screen.
class HomeFocusScope extends InheritedWidget {
  const HomeFocusScope({
    super.key,
    required this.activeZone,
    required this.onActivate,
    required this.onRelease,
    required this.presence,
    this.scrollOffset = 0,
    this.scrollEnergy = 0,
    this.idleCalm = 0,
    required super.child,
  });

  final HomeFocusZone activeZone;
  final ValueChanged<HomeFocusZone> onActivate;
  final VoidCallback onRelease;
  final Animation<double> presence;
  final double scrollOffset;
  final double scrollEnergy;
  final double idleCalm;

  double get presencePhase => presence.value;

  double opacityFor(HomeFocusZone zone) =>
      (HomeFocus.opacity(zone: zone, active: activeZone) +
              HomeReward.ambientLift(zone, activeZone))
          .clamp(0.0, 1.0);

  double glowFor(HomeFocusZone zone) => HomeFocus.glow(
        zone: zone,
        active: activeZone,
      );

  double motionFor(HomeFocusZone zone) => HomeFocus.motion(
        zone: zone,
        active: activeZone,
      );

  double contrastFor(HomeFocusZone zone) => HomeFocus.contrastEmphasis(
        zone: zone,
        active: activeZone,
      );

  double ambientLiftFor(HomeFocusZone zone) =>
      HomeReward.ambientLift(zone, activeZone);

  double get orbRewardBoost => HomeReward.orbBoost(activeZone);

  double get ambientCalm => HomeFocus.ambientCalm(activeZone);

  /// OR-421 — composite stillness when the user rests.
  double get worldCalm => HomeObservatoryPresence.worldCalm(
        focusCalm: ambientCalm,
        idleCalm: idleCalm,
      );

  /// OR-421 — ambient motion follows scroll, never jumps.
  double get ambientEnergy => HomeObservatoryPresence.ambientEnergy(
        scrollEnergy: scrollEnergy,
        idleCalm: idleCalm,
      );

  double observatoryChannel(int id) => HomeObservatoryTime.channel(id);

  double orbLightMemory(HomeOrbProximity proximity, {int seed = 0}) =>
      HomeObservatoryLight.orbMemoryAlpha(
        proximity: proximity,
        worldCalm: worldCalm,
        lightPhase: presencePhase,
        imperfectionSeed: seed,
      );

  static HomeFocusScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<HomeFocusScope>();
    assert(scope != null, 'HomeFocusScope not found');
    return scope!;
  }

  static HomeFocusScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HomeFocusScope>();

  @override
  bool updateShouldNotify(HomeFocusScope oldWidget) =>
      oldWidget.activeZone != activeZone ||
      oldWidget.scrollOffset != scrollOffset ||
      oldWidget.scrollEnergy != scrollEnergy ||
      oldWidget.idleCalm != idleCalm ||
      oldWidget.presence != presence;
}

/// Applies animated emphasis to a composition zone.
class HomeFocusRegion extends StatefulWidget {
  const HomeFocusRegion({
    super.key,
    required this.zone,
    required this.child,
    this.interactive = false,
  });

  final HomeFocusZone zone;
  final Widget child;
  final bool interactive;

  @override
  State<HomeFocusRegion> createState() => _HomeFocusRegionState();
}

class _HomeFocusRegionState extends State<HomeFocusRegion>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  double _currentOpacity = 1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: HomeFocus.transition,
    );
    _opacity = AlwaysStoppedAnimation(_currentOpacity);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncOpacity(animate: false);
  }

  @override
  void didUpdateWidget(covariant HomeFocusRegion oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncOpacity(animate: true);
  }

  void _syncOpacity({required bool animate}) {
    final scope = HomeFocusScope.of(context);
    final target = (scope.opacityFor(widget.zone) *
            (0.94 + scope.worldCalm * 0.06))
        .clamp(0.0, 1.0);

    if ((target - _currentOpacity).abs() < 0.001) return;

    if (!animate) {
      _controller.stop();
      _currentOpacity = target;
      _opacity = AlwaysStoppedAnimation(target);
      return;
    }

    _opacity = Tween<double>(
      begin: _currentOpacity,
      end: target,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: HomeFocus.curve,
    ));
    _controller.forward(from: 0);
    _currentOpacity = target;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = HomeFocusScope.of(context);
    final contrast = scope.contrastFor(widget.zone);
    final parallax = HomePresenceRhythm.parallaxGlass(scope.scrollOffset);

    Widget content = Transform.translate(
      offset: Offset(0, parallax),
      child: AnimatedBuilder(
        animation: _opacity,
        builder: (context, child) {
          return ColorFiltered(
            colorFilter: ColorFilter.matrix(
              HomeFocus.visualMatrix(
                contrast: contrast,
                opacity: _opacity.value.clamp(0.0, 1.0),
              ),
            ),
            child: child,
          );
        },
        child: widget.child,
      ),
    );

    if (!widget.interactive) return content;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => scope.onActivate(widget.zone),
      onPointerUp: (_) => scope.onRelease(),
      onPointerCancel: (_) => scope.onRelease(),
      child: content,
    );
  }
}
