/// Cinematic wait — dark portrait frame, phased copy, never fake progress.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design_system/loading_cinema/oracly_loading_cinema.dart';
import '../../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../../../core/theme/oracly_quiet_motion.dart';
import '../../copy/soul_mate_copy.dart';

class SoulMateDrawWaiting extends StatefulWidget {
  const SoulMateDrawWaiting({
    super.key,
    this.onRetry,
    this.activeSince,
    this.slowAfter = const Duration(seconds: 28),
  });

  final VoidCallback? onRetry;
  final DateTime? activeSince;
  final Duration slowAfter;

  @override
  State<SoulMateDrawWaiting> createState() => _SoulMateDrawWaitingState();
}

class _SoulMateDrawWaitingState extends State<SoulMateDrawWaiting> {
  Timer? _timer;
  Timer? _slowTimer;
  var _phase = 0;
  var _slow = false;

  @override
  void initState() {
    super.initState();
    _armSlowState();
  }

  @override
  void didUpdateWidget(covariant SoulMateDrawWaiting oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeSince != widget.activeSince ||
        oldWidget.slowAfter != widget.slowAfter) {
      _armSlowState();
    }
  }

  void _armSlowState() {
    _slowTimer?.cancel();
    final elapsed = widget.activeSince == null
        ? Duration.zero
        : DateTime.now().difference(widget.activeSince!);
    final remaining = widget.slowAfter - elapsed;
    if (remaining <= Duration.zero) {
      _slow = true;
      return;
    }
    _slow = false;
    _slowTimer = Timer(remaining, () {
      if (mounted) setState(() => _slow = true);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (OraclyQuietMotion.still(context)) {
      _timer?.cancel();
      _timer = null;
      return;
    }
    _timer ??= Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      setState(() {
        _phase = (_phase + 1) % SoulMateCopy.drawingPhases.length;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _slowTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Natural height — portrait stage (~227) + gap + phase copy must not clip.
    return OraclyLoadingCinema(
      kind: OraclyLoadingKind.soulMate,
      message: _slow
          ? SoulMateCopy.drawingSlowTitle
          : SoulMateCopy.drawingPhases[_phase],
      subtitle: _slow
          ? '${SoulMateCopy.drawingSlowBody}\n\n${SoulMateCopy.drawingSlowSecondary}'
          : null,
      // Soulmate elapsed time is presentation only. Its own timer above
      // replaces the generic failure-style failsafe while the server state
      // remains active; no retry callback is exposed here.
      slowAfter: const Duration(days: 365),
    );
  }
}
