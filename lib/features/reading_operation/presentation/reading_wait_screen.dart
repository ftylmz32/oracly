/// Production waiting/countdown screen for Coffee and Palm. Pure
/// presentation: consumes the existing ReadingOperation live state and Gem
/// acceleration wiring via parameters, and touches nothing about how either
/// is computed.
library;

import 'package:flutter/material.dart';

import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/oracly_chrome.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/reading_typography.dart';
import '../../../shared/widgets/oracly_gold_button.dart';
import '../copy/reading_live_copy.dart';
import '../services/reading_live_flow.dart';
import 'reading_wait_countdown_clock.dart';

class ReadingWaitScreen extends StatelessWidget {
  const ReadingWaitScreen({
    super.key,
    required this.liveState,
    this.hero,
    this.onAccelerate,
    this.accelerating = false,
    this.accelerationError,
    this.accelerationCost,
  });

  /// The current server-synced operation state. Null before the operation
  /// is created yet -- the countdown then simply shows 00:00:00.
  final ReadingLiveState? liveState;

  /// Feature-specific art (the real cup/hand photo, its own atmosphere) --
  /// deliberately not owned here, so Coffee/Palm keep their own visual
  /// identity and this screen never touches their capture/validation logic.
  final Widget? hero;

  final VoidCallback? onAccelerate;
  final bool accelerating;
  final String? accelerationError;
  /// Server-quoted Gem cost for the CTA label -- null shows the plain
  /// (no-number) label until the quote arrives; never invented locally.
  final int? accelerationCost;

  @override
  Widget build(BuildContext context) {
    final processing = liveState?.kind == ReadingLiveKind.processing;
    // Cloud Tasks queue concurrency, cold starts, and backoff can legitimately
    // keep a healthy operation `waiting` well past its own readyAt -- this is
    // never a failure, just a still-counting-down UI (00:00:00) that no
    // longer reads as informative. Swap to a neutral "about to start" line
    // instead; the countdown clock itself is untouched for every other case.
    final overdueWaiting = !processing &&
        liveState?.kind == ReadingLiveKind.waiting &&
        (liveState?.displayRemaining(Duration.zero) ?? Duration.zero) <=
            Duration.zero;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.s20,
          vertical: AppSpacing.s24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (hero != null) ...[hero!, SizedBox(height: AppSpacing.s24)],
            Text(
              ReadingLiveCopy.headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTypography.displayFontFamily,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: OraclyChrome.cream,
                height: 1.2,
              ),
            ),
            SizedBox(height: AppSpacing.s8),
            Text(
              ReadingLiveCopy.subtitle,
              textAlign: TextAlign.center,
              style: ReadingTypography.footnote(
                color: OraclyChrome.cream.withValues(alpha: 0.72),
              ),
            ),
            SizedBox(height: AppSpacing.s24),
            if (processing)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: AppSpacing.s12),
                    Text(
                      ReadingLiveCopy.processingDetail,
                      style: ReadingTypography.footnote(
                        color: OraclyChrome.cream.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              )
            else if (overdueWaiting)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: AppSpacing.s12),
                    Text(
                      ReadingLiveCopy.overdueWaiting,
                      style: ReadingTypography.footnote(
                        color: OraclyChrome.cream.withValues(alpha: 0.72),
                      ),
                    ),
                  ],
                ),
              )
            else
              Center(
                child: ReadingWaitCountdownClock(liveState: liveState),
              ),
            SizedBox(height: AppSpacing.s24),
            if (accelerationError != null) ...[
              _AccelerationErrorBanner(message: accelerationError!),
              SizedBox(height: AppSpacing.s16),
            ],
            // Once the free wait is already over, there is nothing left to
            // sell -- the CTA must not even be shown, let alone tappable.
            // The real boundary is enforced server-side (accelerate() itself
            // refuses to charge past readyAt); this is belt-and-suspenders,
            // not the only protection.
            if (!processing && !overdueWaiting)
              OraclyGoldButton(
                label: accelerating
                    ? ReadingLiveCopy.processing
                    : ReadingLiveCopy.accelerateCtaWithCost(accelerationCost),
                onPressed: (accelerating || onAccelerate == null)
                    ? null
                    : onAccelerate,
                expanded: true,
              ),
            SizedBox(height: AppSpacing.s20),
            Text(
              ReadingLiveCopy.backgroundInfo,
              textAlign: TextAlign.center,
              style: ReadingTypography.metadata(
                color: OraclyChrome.cream.withValues(alpha: 0.52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccelerationErrorBanner extends StatelessWidget {
  const _AccelerationErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        borderRadius: AppRadius.md,
        color: Colors.redAccent.withValues(alpha: 0.10),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.32)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: ReadingTypography.footnote(
          color: Colors.redAccent.shade100,
        ),
      ),
    );
  }
}
