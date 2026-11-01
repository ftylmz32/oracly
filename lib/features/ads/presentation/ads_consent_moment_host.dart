/// The only place the initial UMP consent form may appear: wraps the Home
/// tab root and presents the form when — and only when — every one of
/// these holds at the same moment (re-checked after a short settle delay):
///   * ads rolled out and the build usable for ads (else: plain child, the
///     gate is never even created);
///   * UMP reported consent as REQUIRED after the launch refresh and the
///     form has not been shown for this account yet;
///   * no other UMP form is open;
///   * the app is resumed, the Home tab is the visible tab, nothing is
///     pushed over it inside the tab, and the shell itself is the top route
///     (no reading, capture, purchase sheet, dialog or chat above it).
/// It renders nothing of its own: the approved screens are unchanged.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads_rollout.dart';
import '../providers/ads_providers.dart';

class AdsConsentMomentHost extends ConsumerStatefulWidget {
  const AdsConsentMomentHost({
    super.key,
    required this.child,
    this.settle = const Duration(milliseconds: 1500),
  });

  final Widget child;

  /// The screen must stay safe this long before the form is presented.
  final Duration settle;

  @override
  ConsumerState<AdsConsentMomentHost> createState() =>
      _AdsConsentMomentHostState();
}

class _AdsConsentMomentHostState extends ConsumerState<AdsConsentMomentHost>
    with WidgetsBindingObserver {
  Timer? _settleTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _settleTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _schedule();
    } else {
      _settleTimer?.cancel();
      _settleTimer = null;
    }
  }

  bool get _adsUsable =>
      AdsRollout.enabled && ref.read(adsEnvironmentProvider).usable;

  bool _safeMoment() {
    if (!mounted) return false;
    final lifecycle = WidgetsBinding.instance.lifecycleState;
    if (lifecycle != null && lifecycle != AppLifecycleState.resumed) {
      return false;
    }
    if (!TickerMode.valuesOf(context).enabled) return false; // tab hidden
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return false; // pushed in tab
    final tabNavigator = Navigator.maybeOf(context);
    if (tabNavigator != null) {
      final shellRoute = ModalRoute.of(tabNavigator.context);
      if (shellRoute != null && !shellRoute.isCurrent) return false;
    }
    return true;
  }

  void _schedule() {
    if (!mounted || _settleTimer != null || !_adsUsable) return;
    if (!ref.read(adsGateProvider).consentFormPending) return;
    _settleTimer = Timer(widget.settle, () {
      _settleTimer = null;
      if (!mounted || !_adsUsable) return;
      final gate = ref.read(adsGateProvider);
      if (!gate.consentFormPending) return;
      if (!_safeMoment()) {
        // Something sits above Home (a root route this nested widget is not
        // notified about): look again later, only while the form is pending.
        _schedule();
        return;
      }
      unawaited(gate.presentConsentFormAtSafeMoment());
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_adsUsable) return widget.child;
    // Rebuild when the gate learns consent is required, and when this
    // route's visibility changes (ModalRoute / TickerMode dependencies).
    ref.watch(adsGateProvider);
    ModalRoute.of(context);
    TickerMode.valuesOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) => _schedule());
    return widget.child;
  }
}
