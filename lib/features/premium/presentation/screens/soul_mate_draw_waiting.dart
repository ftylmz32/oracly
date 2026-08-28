/// Cinematic wait — dark portrait frame, phased copy, never fake progress.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design_system/loading_cinema/oracly_loading_cinema.dart';
import '../../../../core/design_system/loading_cinema/oracly_loading_kind.dart';
import '../../../../core/theme/oracly_quiet_motion.dart';
import '../../copy/soul_mate_copy.dart';

class SoulMateDrawWaiting extends StatefulWidget {
  const SoulMateDrawWaiting({super.key, this.onRetry});

  final VoidCallback? onRetry;

  @override
  State<SoulMateDrawWaiting> createState() => _SoulMateDrawWaitingState();
}

class _SoulMateDrawWaitingState extends State<SoulMateDrawWaiting> {
  Timer? _timer;
  var _phase = 0;

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Natural height — portrait stage (~227) + gap + phase copy must not clip.
    return OraclyLoadingCinema(
      kind: OraclyLoadingKind.soulMate,
      message: SoulMateCopy.drawingPhases[_phase],
      onRetry: widget.onRetry,
    );
  }
}
