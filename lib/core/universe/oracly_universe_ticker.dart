/// Wall-clock ritual scope. Refreshes at the next daypart, on resume, and
/// when the offset changes. No perpetual animation.
library;

import 'dart:async';

import 'package:flutter/widgets.dart';

import 'oracly_universe_clock.dart';
import 'oracly_universe_scope.dart';
import 'oracly_universe_state.dart';

class OraclyUniverseTicker extends StatefulWidget {
  const OraclyUniverseTicker({
    super.key,
    required this.child,
    this.builder,
    this.now,
    this.previewMoment,
  });

  final Widget child;
  final Widget Function(BuildContext context, OraclyUniverseState state)?
      builder;

  /// Tests inject this. Production uses the device clock.
  final DateTime Function()? now;

  /// Debug launch extra. Ignored when [now] is set, and in release builds.
  final Future<DateTime?> Function()? previewMoment;

  @override
  State<OraclyUniverseTicker> createState() => _OraclyUniverseTickerState();
}

class _OraclyUniverseTickerState extends State<OraclyUniverseTicker>
    with WidgetsBindingObserver {
  late OraclyUniverseState _state;
  DateTime? _locked;
  Timer? _boundary;
  Timer? _guard;

  DateTime _instant() => _locked ?? widget.now?.call() ?? DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _state = OraclyUniverseState.current(_instant());
    _arm();
    unawaited(_loadPreview());
  }

  Future<void> _loadPreview() async {
    if (widget.now != null) return;
    final moment = await widget.previewMoment?.call();
    if (!mounted || moment == null) return;
    setState(() {
      _locked = moment;
      _state = OraclyUniverseState.current(moment);
    });
    _arm();
  }

  void _publish() {
    final now = _instant();
    if (!OraclyUniverseClock.shouldRefresh(
      previous: _state.ritualTime,
      previousOffset: _state.moment.timeZoneOffset,
      now: now,
    )) {
      return;
    }
    setState(() => _state = OraclyUniverseState.current(now));
  }

  void _arm() {
    _boundary?.cancel();
    _guard?.cancel();
    if (_locked != null) return;
    final now = _instant();
    final delay = OraclyUniverseClock.nextBoundary(now).difference(now) +
        const Duration(seconds: 1);
    _boundary = Timer(delay, () {
      if (!mounted) return;
      _publish();
      _arm();
    });
    _guard = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted) return;
      _publish();
    });
  }

  @override
  void didUpdateWidget(covariant OraclyUniverseTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.now == null) return;
    _locked = null;
    _state = OraclyUniverseState.current(_instant());
    _arm();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _locked != null) return;
    _publish();
    _arm();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _boundary?.cancel();
    _guard?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OraclyUniverseScope(
      state: _state,
      child: widget.builder?.call(context, _state) ?? widget.child,
    );
  }
}
