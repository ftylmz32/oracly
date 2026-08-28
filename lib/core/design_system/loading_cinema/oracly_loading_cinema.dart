/// Global discovery loading cinema — something is happening, never stuck.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../shared/widgets/chamber_waiting_orb.dart';
import '../../theme/reading_typography.dart';
import '../oracly_chrome.dart';
import 'loading_stage_astrology.dart';
import 'loading_stage_coffee.dart';
import 'loading_stage_or.dart';
import 'loading_stage_soulmate.dart';
import 'loading_stage_tarot.dart';
import 'loading_stage_yildizname.dart';
import 'oracly_loading_failsafe.dart';
import 'oracly_loading_kind.dart';

/// Feature-shaped wait. No CircularProgressIndicator. No fake %.
class OraclyLoadingCinema extends StatefulWidget {
  const OraclyLoadingCinema({
    super.key,
    required this.kind,
    required this.message,
    this.subtitle,
    this.imagePath,
    this.onRetry,
    this.slowAfter = const Duration(seconds: 28),
    this.compact = false,
    this.stage,
  });

  final OraclyLoadingKind kind;
  final String message;
  final String? subtitle;
  final String? imagePath;
  final VoidCallback? onRetry;
  final Duration slowAfter;
  final bool compact;
  final Widget? stage;

  @override
  State<OraclyLoadingCinema> createState() => _OraclyLoadingCinemaState();
}

class _OraclyLoadingCinemaState extends State<OraclyLoadingCinema> {
  Timer? _slow;
  var _slowed = false;

  @override
  void initState() {
    super.initState();
    _arm();
  }

  @override
  void didUpdateWidget(covariant OraclyLoadingCinema oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message || oldWidget.kind != widget.kind) {
      _slow?.cancel();
      _slowed = false;
      _arm();
    }
  }

  void _arm() {
    _slow = Timer(widget.slowAfter, () {
      if (mounted) setState(() => _slowed = true);
    });
  }

  @override
  void dispose() {
    _slow?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_slowed) {
      return Center(
        child: OraclyLoadingFailsafe(
          onRetry: widget.onRetry,
          kind: widget.kind,
        ),
      );
    }
    return Semantics(
      liveRegion: true,
      label: widget.message,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.stage ?? _defaultStage(),
              SizedBox(height: widget.compact ? 14 : 20),
              Text(
                widget.message,
                textAlign: TextAlign.center,
                style: ReadingTypography.opening(
                  color: OraclyChrome.cream.withValues(alpha: 0.90),
                ),
              ),
              if (widget.subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  widget.subtitle!,
                  textAlign: TextAlign.center,
                  style: ReadingTypography.secondary(
                    color: OraclyChrome.cream.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _defaultStage() {
    final compact = widget.compact;
    switch (widget.kind) {
      case OraclyLoadingKind.coffee:
        return LoadingStageCoffee(size: compact ? 140 : 180);
      case OraclyLoadingKind.tarot:
        return LoadingStageTarot(size: compact ? 132 : 168);
      case OraclyLoadingKind.soulMate:
        return LoadingStageSoulMate(width: compact ? 132 : 168);
      case OraclyLoadingKind.yildizname:
        return LoadingStageYildizname(size: compact ? 140 : 176);
      case OraclyLoadingKind.orPresence:
        return LoadingStageOr(size: compact ? 40 : 52);
      case OraclyLoadingKind.astrology:
        return LoadingStageAstrology(size: compact ? 140 : 176);
      case OraclyLoadingKind.chamber:
        return ChamberWaitingOrb(size: compact ? 56 : 88);
    }
  }
}
