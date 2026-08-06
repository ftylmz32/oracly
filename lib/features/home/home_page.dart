/// OR-999 / OR-411 / OR-412 / OR-415 — Home Screen composition master layout.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/copy/first_session_copy.dart';
import '../../core/navigation/universe/universe_map_sheet.dart';
import '../../core/navigation/oracly_navigation_service.dart';
import '../../core/universe/oracly_universe_layer.dart';
import '../../shared/widgets/oracly_scaffold.dart';
import 'theme/home_composition.dart';
import 'theme/home_focus.dart';
import 'theme/home_architecture.dart';
import 'theme/home_observatory.dart';
import 'theme/home_presence.dart';
import '../daily_ritual/widgets/daily_ritual_card.dart';
import 'widgets/hero_header.dart';
import 'widgets/hero_orb_v3/hero_orb.dart';
import 'widgets/home_cinematic_background.dart';
import 'widgets/mystic_feature_grid.dart';
import '../oracle_presence/oracle_presence_venue.dart';
import '../oracle_presence/widgets/oracle_whisper_line.dart';
import 'widgets/premium_banner.dart';

/// Home screen — single luxury composition with emotional focus gravity.
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  HomeFocusZone _activeZone = HomeFocusZone.none;
  late final AnimationController _presence;
  double _scrollOffset = 0;
  double _scrollVelocity = 0;
  double _idleCalm = 0;
  DateTime _lastMotion = DateTime.now();
  double _lastScrollSample = 0;
  DateTime _lastScrollSampleTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _presence = AnimationController(
      vsync: this,
      duration: HomePresenceRhythm.masterCycle,
    );
    _presence.value = HomePresenceRhythm.clockPhase();
    _presence.repeat();
  }

  @override
  void dispose() {
    _presence.dispose();
    super.dispose();
  }

  void _syncIdleCalm() {
    final idleMs = DateTime.now().difference(_lastMotion).inMilliseconds;
    final targetIdle = HomeObservatoryPresence.idleCalm(idleMs);
    if ((targetIdle - _idleCalm).abs() > 0.02) {
      _idleCalm = targetIdle;
    }
  }

  void _activate(HomeFocusZone zone) {
    _lastMotion = DateTime.now();
    _syncIdleCalm();
    if (_activeZone != zone) setState(() => _activeZone = zone);
  }

  void _release() {
    _lastMotion = DateTime.now();
    _syncIdleCalm();
    if (_activeZone != HomeFocusZone.none) {
      setState(() => _activeZone = HomeFocusZone.none);
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification ||
        notification is ScrollMetricsNotification) {
      final offset = notification.metrics.pixels;
      final now = DateTime.now();
      if (notification is ScrollUpdateNotification) {
        final dtMs = now.difference(_lastScrollSampleTime).inMilliseconds.clamp(1, 400);
        final delta = (offset - _lastScrollSample).abs();
        final vel = delta / dtMs * 1000;
        _scrollVelocity = _scrollVelocity * 0.72 + vel * 0.28;
        _lastScrollSample = offset;
        _lastScrollSampleTime = now;
        _lastMotion = now;
      }
      if ((offset - _scrollOffset).abs() > 2.0) {
        setState(() {
          _scrollOffset = offset;
          _syncIdleCalm();
          if (_idleCalm > 0.02) _idleCalm *= 0.85;
        });
      }
    }
    return false;
  }

  double get _scrollEnergy =>
      HomeObservatoryPresence.scrollEnergy(_scrollVelocity);

  @override
  Widget build(BuildContext context) {
    return OraclyUniverseTicker(
      child: HomeFocusScope(
      activeZone: _activeZone,
      onActivate: _activate,
      onRelease: _release,
      presence: _presence,
      scrollOffset: _scrollOffset,
      scrollEnergy: _scrollEnergy,
      idleCalm: _idleCalm,
      child: OraclyScaffold(
        backgroundOverlay: const HomeCosmicBackground(),
        child: NotificationListener<ScrollNotification>(
          onNotification: _onScroll,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ).copyWith(
              top: HomeComposition.screenTop,
              bottom: HomeComposition.screenBottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    RepaintBoundary(
                      child: HomeFocusRegion(
                        zone: HomeFocusZone.header,
                        child: Consumer(
                          builder: (context, ref, _) {
                            final profile = ref.watch(userProfileProvider);
                            final isFirst =
                                ref.watch(isFirstSessionProvider).value ??
                                    true;
                            final name = profile.value?.name.trim();
                            return HeroHeader(
                              userName: (name != null && name.isNotEmpty)
                                  ? name
                                  : FirstSessionCopy.homeGuestName,
                              subtitle: isFirst
                                  ? FirstSessionCopy.homeSubtitleNew
                                  : FirstSessionCopy.homeSubtitleReturning,
                              onMenuTap: () => UniverseMapSheet.open(context),
                              onPremiumTap: () => OraclyNavigationService
                                  .openPremium(context),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: HomeComposition.headerToOrb),
                    RepaintBoundary(
                      child: Transform.translate(
                        offset: HomeComposition.depthOffset(
                          HomeComposition.depthFeatured,
                        ),
                        child: const HomeFocusRegion(
                          zone: HomeFocusZone.orb,
                          child: _HeroOrbChamber(),
                        ),
                      ),
                    ),
                    const OracleWhisperLine(venue: OraclePresenceVenue.home),
                    SizedBox(height: HomeComposition.orbToSpread - AppSpacing.sm),
                    RepaintBoundary(
                      child: Transform.translate(
                        offset: HomeComposition.depthOffset(
                          HomeComposition.depthInteractive,
                        ),
                        child: const HomeFocusRegion(
                          zone: HomeFocusZone.spread,
                          interactive: true,
                          child: MysticFeatureGrid(
                            band: HomeCompositionBand.explore,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: HomeComposition.spreadToDaily),
                    RepaintBoundary(
                      child: Transform.translate(
                        offset: HomeComposition.depthOffset(
                          HomeComposition.depthGlass,
                        ),
                        child: const HomeFocusRegion(
                          zone: HomeFocusZone.daily,
                          interactive: true,
                          child: DailyRitualCard(),
                        ),
                      ),
                    ),
                    SizedBox(height: HomeComposition.dailyToPremium),
                    RepaintBoundary(
                      child: Transform.translate(
                        offset: HomeComposition.depthOffset(
                          HomeComposition.depthGlass,
                        ),
                        child: const HomeFocusRegion(
                          zone: HomeFocusZone.premium,
                          interactive: true,
                          child: PremiumBanner(),
                        ),
                      ),
                    ),
                    SizedBox(height: HomeComposition.premiumToDiscovery),
                    RepaintBoundary(
                      child: Transform.translate(
                        offset: HomeComposition.depthOffset(
                          HomeComposition.depthInteractive,
                        ),
                        child: const HomeFocusRegion(
                          zone: HomeFocusZone.ai,
                          interactive: true,
                          child: MysticFeatureGrid(
                            band: HomeCompositionBand.reflect,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: HomeComposition.aiToCosmic),
                    RepaintBoundary(
                      child: Transform.translate(
                        offset: HomeComposition.depthOffset(
                          HomeComposition.depthGlass,
                        ),
                        child: const HomeFocusRegion(
                          zone: HomeFocusZone.cosmic,
                          interactive: true,
                          child: MysticFeatureGrid(
                            band: HomeCompositionBand.understand,
                          ),
                        ),
                      ),
                    ),
                  ],
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

/// Hero orb focal chamber — pedestal light follows emotional gravity.
class _HeroOrbChamber extends StatelessWidget {
  const _HeroOrbChamber();

  @override
  Widget build(BuildContext context) {
    final scope = HomeFocusScope.of(context);
    final orbSize = HomeComposition.orbSize;
    final halo = orbSize * HomeComposition.orbHaloScale;
    final glowStrength = scope.glowFor(HomeFocusZone.orb);
    final rewardBoost = scope.orbRewardBoost;
    final parallax =
        HomePresenceRhythm.parallaxForeground(scope.scrollOffset);

    return AnimatedBuilder(
      animation: scope.presence,
      builder: (context, child) {
        final phase = scope.presencePhase;
        final veil = HomePresenceRhythm.ambientVeil(phase);
        final worldVeil = scope.worldCalm;
        final combinedVeil = (veil * (0.88 + worldVeil * 0.12)).clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, parallax),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              IgnorePointer(
                child: Opacity(
                  opacity: (0.55 + glowStrength * 0.18).clamp(0.0, 1.0) * combinedVeil,
                  child: Container(
                    width: halo * 1.08,
                    height: halo * 0.85,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: HomeComposition.orbChamberGlow(phase),
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: ((0.78 + glowStrength * 0.22) *
                          rewardBoost.clamp(1.0, 1.05) *
                          combinedVeil)
                      .clamp(0.0, 1.0),
                  duration: HomeFocus.transition,
                  curve: HomeFocus.curve,
                  child: Container(
                    width: halo,
                    height: halo * 0.72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: HomeComposition.orbPedestalGlow,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: orbSize * 0.48,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: combinedVeil.clamp(0.0, 1.0),
                    child: HomeOrbSpillColumn(
                      width: halo * 0.52,
                      height: orbSize * 0.36,
                    ),
                  ),
                ),
              ),
              child!,
            ],
          ),
        );
      },
      child: HeroOrb(size: orbSize),
    );
  }
}
