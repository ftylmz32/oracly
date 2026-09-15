/// Live HH:MM:SS display driven by the server-synced ReadingOperation
/// snapshot -- never device wall clock. Purely a per-second repaint of
/// [ReadingLiveState.displayRemaining]; it never recomputes or replaces the
/// server-authoritative wait itself.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../models/reading_operation_snapshot.dart';
import '../services/reading_live_flow.dart';
import 'reading_wait_countdown_face.dart';

class ReadingWaitCountdownClock extends StatefulWidget {
  const ReadingWaitCountdownClock({super.key, required this.liveState});

  final ReadingLiveState? liveState;

  @override
  State<ReadingWaitCountdownClock> createState() =>
      _ReadingWaitCountdownClockState();
}

class _ReadingWaitCountdownClockState
    extends State<ReadingWaitCountdownClock> {
  final Stopwatch _stopwatch = Stopwatch()..start();
  Timer? _ticker;
  ReadingOperationSnapshot? _syncedSnapshot;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Not setState: the first build hasn't happened yet, so the field is
    // simply read fresh -- no rebuild needs to be requested for it.
    _syncedSnapshot = widget.liveState?.snapshot;
    _remaining = _compute();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void didUpdateWidget(covariant ReadingWaitCountdownClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    _resync();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  bool _sameSync(ReadingOperationSnapshot? a, ReadingOperationSnapshot? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    return a.operationId == b.operationId &&
        a.readyAt == b.readyAt &&
        a.serverNow == b.serverNow;
  }

  Duration _compute() =>
      widget.liveState?.displayRemaining(_stopwatch.elapsed) ?? Duration.zero;

  void _resync() {
    final snap = widget.liveState?.snapshot;
    // A genuinely fresh server sync (new operation, or a re-fetched
    // snapshot after background/resume/restart) resets the monotonic
    // stopwatch to that sync point -- this is what makes the countdown
    // correct again immediately, without ever consulting device time.
    if (!_sameSync(snap, _syncedSnapshot)) {
      _syncedSnapshot = snap;
      _stopwatch
        ..reset()
        ..start();
    }
    _tick();
  }

  void _tick() {
    if (!mounted) return;
    final next = _compute();
    if (next == _remaining) return;
    setState(() => _remaining = next);
  }

  @override
  Widget build(BuildContext context) {
    return ReadingWaitCountdownFace(remaining: _remaining);
  }
}
