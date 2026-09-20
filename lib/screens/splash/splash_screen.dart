/// App entry — FinalOraclySplash first, destination underlay after gate + paint.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/app_providers.dart';
import '../../core/auth/account_deletion_pending_state.dart';
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

  /// Brand splash painted — destination still waits on the deletion gate.
  bool _splashPainted = false;

  /// Heavy Home/Onboarding mounts only after splash art + gate resolve.
  bool _destinationMounted = false;

  @override
  void initState() {
    super.initState();
    SplashStartupLog.mark('ROOT_FIRST_BUILD');
    final storage = ref.read(localStorageProvider);
    _onboardingCompleted =
        storage.getBool(LocalOnboardingRepository.completedKey) ?? false;
    AccountDeletionPendingState.phase.addListener(_onGateChanged);
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    AccountDeletionPendingState.phase.removeListener(_onGateChanged);
    super.dispose();
  }

  void _onGateChanged() {
    if (!mounted) return;
    _tryMountDestination();
  }

  Future<void> _bootstrap() async {
    try {
      // Routing-critical local gate BEFORE any owner-bound destination.
      await AccountDeletionPendingState.resolveFromLocalStorage(
        ref.read(localStorageProvider),
      );
      if (!mounted) return;
      _tryMountDestination();

      final completed = await splashFastOnboarding(ref);
      if (!mounted) return;
      if (completed != _onboardingCompleted) {
        setState(() => _onboardingCompleted = completed);
      }
      if (AccountDeletionPendingState.allowsOwnerBoundExperience) {
        unawaited(splashDeferredBoot(ref));
        splashScheduleWarmup(ProviderScope.containerOf(context, listen: false));
      }
    } catch (_) {
      if (!mounted) return;
      if (AccountDeletionPendingState.isUnresolved) {
        AccountDeletionPendingState.markClear();
      }
      _tryMountDestination();
      unawaited(splashResilientBoot(ref));
      if (AccountDeletionPendingState.allowsOwnerBoundExperience) {
        splashScheduleWarmup(ProviderScope.containerOf(context, listen: false));
      }
    }
  }

  void _onSplashFirstFrame() {
    if (!mounted || _splashPainted) return;
    SplashStartupLog.mark('SPLASH_FIRST_FRAME');
    _splashPainted = true;
    _tryMountDestination();
  }

  void _tryMountDestination() {
    if (!mounted || _destinationMounted) return;
    if (!_splashPainted) return;
    if (AccountDeletionPendingState.isUnresolved) return;
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
    if (AccountDeletionPendingState.isUnresolved) {
      await AccountDeletionPendingState.resolveFromLocalStorage(
        ref.read(localStorageProvider),
      );
    }
    if (!mounted) return;

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

    if (!AccountDeletionPendingState.allowsOwnerBoundExperience) return;

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
          // Never blank; never Home while gate unresolved.
          SplashDestination.unresolvedUnderlay(),
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
