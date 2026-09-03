/// App entry — FinalOraclySplash first, destination underlay after first splash frame.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/data/repositories/local_onboarding_repository.dart';
import '../../core/l10n/l10n.dart';
import '../../core/navigation/oracly_navigator_key.dart';
import '../../core/navigation/oracly_routes.dart';
import '../../core/notifications/oracly_notification_tap_router.dart';
import '../../core/theme/oracly_reduced_motion.dart';
import '../../features/share_reopen/services/share_link_opener.dart';
import 'splash_boot.dart';
import 'splash_brand_overlay.dart';
import 'splash_cinema_prefs.dart';
import 'splash_destination.dart';
import 'splash_startup_log.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  static String get tagline => OraclyL10n.t('splash.tagline');

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  late bool _onboardingCompleted;
  bool _overlayVisible = true;
  bool _navigated = false;

  /// Heavy Home/Onboarding mounts only after splash art has painted.
  bool _destinationMounted = false;

  @override
  void initState() {
    super.initState();
    SplashStartupLog.mark('ROOT_FIRST_BUILD');
    final storage = ref.read(localStorageProvider);
    _onboardingCompleted =
        storage.getBool(LocalOnboardingRepository.completedKey) ?? false;
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    try {
      // Promote then read — never race an unawaited promote against routing.
      final completed = await splashFastOnboarding(ref);
      if (!mounted) return;
      if (completed != _onboardingCompleted) {
        setState(() => _onboardingCompleted = completed);
      }
      // Gems/reconcile stay non-blocking for the route decision.
      unawaited(splashDeferredBoot(ref));
      splashScheduleWarmup(ref);
    } catch (_) {
      if (!mounted) return;
      unawaited(splashResilientBoot(ref));
      splashScheduleWarmup(ref);
    }
  }

  void _onSplashFirstFrame() {
    if (!mounted || _destinationMounted) return;
    SplashStartupLog.mark('DESTINATION_READY');
    setState(() => _destinationMounted = true);
  }

  void _onOverlayDone() {
    if (!mounted || _navigated) return;
    _navigated = true;
    unawaited(SplashCinemaPrefs.markSeen(ref.read(localStorageProvider)));
    setState(() => _overlayVisible = false);
    unawaited(_commitDestination());
  }

  Future<void> _commitDestination() async {
    // Cinema may finish before bootstrap; re-resolve on durable storage.
    final completed = await splashFastOnboarding(ref);
    if (!mounted) return;
    if (completed != _onboardingCompleted) {
      setState(() => _onboardingCompleted = completed);
    }
    final dest = SplashDestination.build(
      onboardingCompleted: completed,
      storage: ref.read(localStorageProvider),
    );
    SplashDestination.commitRoute(context, dest);
    ShareLinkOpener.openPending();
    OraclyNotificationTapRouter.openPending(context);
    final name = WidgetsBinding.instance.platformDispatcher.defaultRouteName;
    if (name == OraclyRoutes.chat) {
      oraclyNavigatorKey.currentState?.pushNamed(OraclyRoutes.chat);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storage = ref.read(localStorageProvider);
    final reduced = OraclyReducedMotion.of(context);
    return Scaffold(
      backgroundColor: SplashDestination.midnight,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Lightweight base — never blank; do NOT build Home on first frame.
          const ColoredBox(
            color: SplashDestination.midnight,
            child: SizedBox.expand(),
          ),
          if (_destinationMounted)
            SplashDestination.build(
              onboardingCompleted: _onboardingCompleted,
              storage: storage,
            ),
          if (_overlayVisible)
            FinalOraclySplash(
              reduced: reduced,
              onFirstFrame: _onSplashFirstFrame,
              onDone: _onOverlayDone,
            ),
        ],
      ),
    );
  }
}
