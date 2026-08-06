/// OR-436 — Observatory whisper — secondary to the hero orb.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/oracly_brand_signature.dart';
import '../../home/theme/home_focus.dart';
import '../oracle_presence_rotator.dart';
import '../oracle_presence_venue.dart';

/// A single atmospheric line — never competes with the orb.
class OracleWhisperLine extends StatefulWidget {
  const OracleWhisperLine({
    super.key,
    required this.venue,
    this.textAlign = TextAlign.center,
  });

  final OraclePresenceVenue venue;
  final TextAlign textAlign;

  @override
  State<OracleWhisperLine> createState() => _OracleWhisperLineState();
}

class _OracleWhisperLineState extends State<OracleWhisperLine>
    with SingleTickerProviderStateMixin {
  String? _line;
  late final AnimationController _fade;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _fade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _opacity = CurvedAnimation(
      parent: _fade,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
    );
    _load();
  }

  Future<void> _load() async {
    final line = await OraclePresenceRotator.current(widget.venue);
    if (!mounted) return;
    setState(() => _line = line);
    await Future<void>.delayed(const Duration(milliseconds: 480));
    if (mounted) _fade.forward();
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final line = _line;
    if (line == null || line.isEmpty) {
      return SizedBox(height: AppSpacing.sm);
    }

    final scope = HomeFocusScope.maybeOf(context);
    final idleLift = scope?.idleCalm ?? 0.5;
    final focusDim =
        scope != null ? HomeFocus.restingOpacity(HomeFocusZone.header) : 0.82;
    final baseAlpha = 0.34 + idleLift * 0.10;
    final alpha = (baseAlpha * (0.88 + focusDim * 0.12)).clamp(0.28, 0.52);

    return FadeTransition(
      opacity: _opacity,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Text(
          line,
          textAlign: widget.textAlign,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: OraclySignatureTypography.whisperBody(
            fontSize: 12,
            alpha: alpha,
          ).copyWith(
            fontStyle: FontStyle.italic,
            height: 1.65,
            letterSpacing: 0.28,
          ),
        ),
      ),
    );
  }
}
